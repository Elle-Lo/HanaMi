import FirebaseFirestore
import CoreLocation

class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - Treasure Handling

    // 獲取用戶儲存的寶藏列表 (最多三筆)
    func fetchRandomTreasures(userID: String, completion: @escaping (Result<[Treasure], Error>) -> Void) {
        let userDocument = db.collection("Users").document(userID)
        
        userDocument.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let treasureList = data["treasureList"] as? [String] else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户文档不存在"])))
                return
            }
            
            // 随机选取最多三笔数据
            let randomTreasures = treasureList.shuffled().prefix(3)
            var fetchedTreasures: [Treasure] = []
            let dispatchGroup = DispatchGroup()

            for treasureId in randomTreasures {
                dispatchGroup.enter()
                
                self.fetchTreasure(userID: userID, treasureID: treasureId) { result in
                    switch result {
                    case .success(let treasure):
                        fetchedTreasures.append(treasure)
                    case .failure(let error):
                        print("Error fetching treasure: \(error)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(.success(fetchedTreasures))
            }
        }
    }

    // 保存寶藏及其內容
    func saveTreasure(userID: String, coordinate: CLLocationCoordinate2D, locationName: String, category: String, isPublic: Bool, contents: [TreasureContent], completion: @escaping (Result<Void, Error>) -> Void) {
        let treasureID = db.collection("Treasures").document().documentID
        let treasureData: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "locationName": locationName,
            "category": category,
            "isPublic": isPublic,
            "createdTime": Timestamp()
        ]

        let treasureRef = db.collection("Treasures").document(treasureID)

        // 保存寶藏基本資料
        treasureRef.setData(treasureData) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }

            // 保存內容到 Treasure 子集合中
            self.saveTreasureContents(treasureID: treasureID, contents: contents) { result in
                switch result {
                case .success():
                    // 更新使用者的 treasureList
                    self.addTreasureIDToUser(userID: userID, treasureID: treasureID, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // 更新使用者的 treasureList
    private func addTreasureIDToUser(userID: String, treasureID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userDocRef = db.collection("Users").document(userID)
        
        // 使用 Firestore 的 arrayUnion 方法將寶藏ID添加到 treasureList 中
        userDocRef.updateData([
            "treasureList": FieldValue.arrayUnion([treasureID])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // 保存寶藏內容
    private func saveTreasureContents(treasureID: String, contents: [TreasureContent], completion: @escaping (Result<Void, Error>) -> Void) {
        let contentCollectionRef = db.collection("Treasures").document(treasureID).collection("Contents")
        let dispatchGroup = DispatchGroup()

        for content in contents {
            dispatchGroup.enter()
            let contentRef = contentCollectionRef.document(content.id)

            do {
                try contentRef.setData(from: content) { error in
                    if let error = error {
                        completion(.failure(error))
                    }
                    dispatchGroup.leave()
                }
            } catch let error {
                completion(.failure(error))
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(.success(()))
        }
    }
    
    // 獲取 Treasure 資料
    func fetchTreasure(userID: String, treasureID: String, completion: @escaping (Result<Treasure, Error>) -> Void) {
        let docRef = db.collection("Treasures").document(treasureID)
        
        docRef.getDocument(as: Treasure.self) { result in
            switch result {
            case .success(let treasure):
                completion(.success(treasure))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // 獲取 Treasure 內容
    func fetchTreasureContents(treasureID: String, completion: @escaping (Result<[TreasureContent], Error>) -> Void) {
        db.collection("Treasures").document(treasureID).collection("Contents").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                do {
                    let contents = try snapshot.documents.map { try $0.data(as: TreasureContent.self) }
                    completion(.success(contents))
                } catch let error {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Category Handling

    // 加載類別
    func loadCategories(userID: String, defaultCategories: [String], completion: @escaping ([String]) -> Void) {
        let userDocument = db.collection("Users").document(userID)

        userDocument.addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error fetching Firestore document: \(error)")
                completion(defaultCategories) // 加載失敗時使用預設類別
            } else if let document = documentSnapshot, document.exists {
                if let categoryArray = document.data()?["category"] as? [String] {
                    completion(categoryArray)
                } else {
                    // 如果文檔存在但沒有 category，設置預設類別
                    self.setDefaultCategories(userID: userID, defaultCategories: defaultCategories) {
                        completion(defaultCategories)
                    }
                }
            } else {
                // 如果文檔不存在，設置預設類別
                self.setDefaultCategories(userID: userID, defaultCategories: defaultCategories) {
                    completion(defaultCategories)
                }
            }
        }
    }

    // 設置 Firestore 的預設類別
    private func setDefaultCategories(userID: String, defaultCategories: [String], completion: @escaping () -> Void) {
        let userDocument = db.collection("Users").document(userID)

        userDocument.setData([
            "category": defaultCategories
        ]) { error in
            if let error = error {
                print("Error setting default categories: \(error)")
            } else {
                print("Default categories set in Firestore")
            }
            completion()
        }
    }

    // 添加新類別到 Firestore
    func addCategory(userID: String, category: String, completion: @escaping (Bool) -> Void) {
        let userDocument = db.collection("Users").document(userID)

        userDocument.updateData([
            "category": FieldValue.arrayUnion([category])
        ]) { error in
            if let error = error {
                print("Error updating Firestore: \(error)")
                completion(false)
            } else {
                print("Category updated successfully in Firestore")
                completion(true)
            }
        }
    }

    // 刪除類別
    func deleteCategory(userID: String, category: String, completion: @escaping (Bool) -> Void) {
        let userDocument = db.collection("Users").document(userID)

        userDocument.updateData([
            "category": FieldValue.arrayRemove([category])
        ]) { error in
            if let error = error {
                print("Error deleting category from Firestore: \(error)")
                completion(false)
            } else {
                print("Category deleted successfully in Firestore")
                completion(true)
            }
        }
    }
}
