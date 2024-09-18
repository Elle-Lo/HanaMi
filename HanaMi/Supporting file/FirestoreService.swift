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
                  let treasureList = data["treasureList"] as? [String], !treasureList.isEmpty else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户文档不存在或宝藏列表为空"])))
                return
            }
            
            let selectedTreasureIDs = Array(treasureList.shuffled().prefix(3))
            var fetchedTreasures: [Treasure] = []
            let dispatchGroup = DispatchGroup()

            for treasureID in selectedTreasureIDs {
                dispatchGroup.enter()
                
                let treasureRef = self.db.collection("Users").document(userID).collection("Treasures").document(treasureID)
                
                treasureRef.getDocument { (treasureDoc, error) in
                    if let error = error {
                        print("Error fetching treasure: \(error.localizedDescription)")
                        dispatchGroup.leave()
                        return
                    }
                    
                    guard let treasureData = treasureDoc?.data(), let treasureID = treasureDoc?.documentID else {
                        print("Treasure data not found for ID: \(treasureID)")
                        dispatchGroup.leave()
                        return
                    }

                    
                    let category = treasureData["category"] as? String ?? "Unknown"
                    let locationName = treasureData["locationName"] as? String ?? "Unknown Location"
                    let latitude = treasureData["latitude"] as? Double ?? 0.0
                    let longitude = treasureData["longitude"] as? Double ?? 0.0
                    let isPublic = treasureData["isPublic"] as? Bool ?? true

                 
                    treasureRef.collection("Contents").getDocuments { (contentsSnapshot, contentError) in
                        var contents: [TreasureContent] = []
                        if let contentDocuments = contentsSnapshot?.documents {
                        
                            for contentDoc in contentDocuments {
                                if let contentTypeString = contentDoc.data()["type"] as? String,
                                   let contentType = ContentType(rawValue: contentTypeString),
                                   let index = contentDoc.data()["index"] as? Int {
                                    let contentValue = contentDoc.data()["content"] as? String ?? ""
                                    let content = TreasureContent(id: contentDoc.documentID, type: contentType, content: contentValue, index: index)
                                    contents.append(content)
                                }
                            }
                            
               
                            contents.sort { $0.index < $1.index }
                        }
                        
                     
                        let treasure = Treasure(
                            id: treasureID,
                            category: category,
                            createdTime: Date(),
                            isPublic: isPublic,
                            latitude: latitude,
                            longitude: longitude,
                            locationName: locationName,
                            contents: contents
                        )
                        
                        fetchedTreasures.append(treasure)
                        dispatchGroup.leave()
                    }
                }
            }
            
        
            dispatchGroup.notify(queue: .main) {
                if fetchedTreasures.isEmpty {
                    print("No treasures found for user \(userID)")
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有找到宝藏"])))
                } else {
                    completion(.success(fetchedTreasures))
                }
            }
        }
    }



    func saveTreasure(userID: String, coordinate: CLLocationCoordinate2D, locationName: String, category: String, isPublic: Bool, contents: [TreasureContent], completion: @escaping (Result<Void, Error>) -> Void) {
       
        let treasureID = db.collection("Users").document(userID).collection("Treasures").document().documentID
        let treasureData: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "locationName": locationName,
            "category": category,
            "isPublic": isPublic,
            "createdTime": Timestamp()
        ]
        
        let treasureRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)

     
        treasureRef.setData(treasureData) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }

            self.saveTreasureContents(treasureID: treasureID, userID: userID, contents: contents) { result in
                switch result {
                case .success():
                  
                    self.addTreasureIDToUser(userID: userID, treasureID: treasureID, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }



    private func addTreasureIDToUser(userID: String, treasureID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userDocRef = db.collection("Users").document(userID)
    
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

    private func saveTreasureContents(treasureID: String, userID: String, contents: [TreasureContent], completion: @escaping (Result<Void, Error>) -> Void) {
        let contentCollectionRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID).collection("Contents")
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
    
//    func fetchPublicTreasures(completion: @escaping (Result<[Treasure], Error>) -> Void) {
//        let publicTreasuresRef = db.collectionGroup("Treasures").whereField("isPublic", isEqualTo: true)
//        
//        publicTreasuresRef.getDocuments { snapshot, error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                let treasures = snapshot?.documents.compactMap { try? $0.data(as: Treasure.self) }
//                completion(.success(treasures ?? []))
//            }
//        }
//    }
    
    // 查詢公開的寶藏，只獲取經緯度和 treasureID
    func fetchPublicTreasuresNear(coordinate: CLLocationCoordinate2D, radius: Double, completion: @escaping (Result<[TreasureSummary], Error>) -> Void) {
        let location = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let publicTreasuresQuery = db.collectionGroup("Treasures")
            .whereField("isPublic", isEqualTo: true)
            // 添加你的地理範圍查詢條件

        publicTreasuresQuery.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let treasures = snapshot?.documents.compactMap { document -> TreasureSummary? in
                    let data = document.data()
                    
                    // documentID 不需要使用 guard let，直接使用即可
                    let treasureID = document.documentID
                    
                    // 這裡仍然需要檢查 latitude 和 longitude
                    guard let latitude = data["latitude"] as? Double,
                          let longitude = data["longitude"] as? Double else {
                        return nil
                    }
                    
                    return TreasureSummary(id: treasureID, latitude: latitude, longitude: longitude)
                }
                completion(.success(treasures ?? []))
            }
        }
    }


    // MARK: - Category Handling
    func loadCategories(userID: String, defaultCategories: [String], completion: @escaping ([String]) -> Void) {
        let userDocument = db.collection("Users").document(userID)

        // 一次性獲取 Firestore 中的類別數據
        userDocument.getDocument { documentSnapshot, error in
            if let error = error {
                print("Error fetching Firestore document: \(error)")
                completion(defaultCategories) 
            } else if let document = documentSnapshot, document.exists {
                if let categoryArray = document.data()?["category"] as? [String], !categoryArray.isEmpty {
                   
                    completion(categoryArray)
                } else {
                    
                    self.setDefaultCategories(userID: userID, defaultCategories: defaultCategories) {
                        completion(defaultCategories)
                    }
                }
            } else {
              
                self.setDefaultCategories(userID: userID, defaultCategories: defaultCategories) {
                    completion(defaultCategories)
                }
            }
        }
    }
   
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
