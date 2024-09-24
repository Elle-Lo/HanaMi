import FirebaseFirestore
import CoreLocation

class FirestoreService {
    private let db = Firestore.firestore()
    
    // MARK: - Treasure Handling
    
    // 随机获取用户保存的宝藏（最多三笔）
    func fetchRandomTreasures(userID: String, completion: @escaping (Result<[Treasure], Error>) -> Void) {
        let userDocument = db.collection("Users").document(userID)
        
        userDocument.getDocument { [weak self] (document, error) in
            guard let self = self, let document = document, document.exists else {
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "文档不存在或宝藏列表为空"])))
                return
            }
            
            guard let treasureList = document.data()?["treasureList"] as? [String], !treasureList.isEmpty else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "宝藏列表为空"])))
                return
            }
            
            let selectedTreasureIDs = Array(treasureList.shuffled().prefix(3))
            var fetchedTreasures: [Treasure] = []
            let dispatchGroup = DispatchGroup()
            
            for treasureID in selectedTreasureIDs {
                dispatchGroup.enter()
                self.fetchTreasure(userID: userID, treasureID: treasureID) { result in
                    switch result {
                    case .success(let treasure):
                        fetchedTreasures.append(treasure)
                    case .failure(let error):
                        print("Error fetching treasure: \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                if fetchedTreasures.isEmpty {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有找到宝藏"])))
                } else {
                    completion(.success(fetchedTreasures))
                }
            }
        }
    }
    
    // 保存新宝藏及其内容 並將寶藏id存取到treasureList中
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
            } else {
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
    }
    
    // 保存宝藏詳細内容
    func saveTreasureContents(treasureID: String, userID: String, contents: [TreasureContent], completion: @escaping (Result<Void, Error>) -> Void) {
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
    
    // 将宝藏ID加入用户的treasure list
     func addTreasureIDToUser(userID: String, treasureID: String, completion: @escaping (Result<Void, Error>) -> Void) {
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
    
    //抓取treasure的資料
    func fetchTreasure(userID: String, treasureID: String, completion: @escaping (Result<Treasure, Error>) -> Void) {
        let treasureRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)
        
        // 首先获取 Treasure 文档数据
        treasureRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "宝藏不存在"])))
                return
            }
            
            let data = document.data() ?? [:]
            
            guard let category = data["category"] as? String,
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double,
                  let locationName = data["locationName"] as? String,
                  let isPublic = data["isPublic"] as? Bool,
                  let timestamp = data["createdTime"] as? Timestamp else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "数据格式不匹配"])))
                return
            }

            // 创建一个 Treasure 对象，不包含内容
            var treasure = Treasure(
                id: treasureID,
                category: category,
                createdTime: timestamp.dateValue(),
                isPublic: isPublic,
                latitude: latitude,
                longitude: longitude,
                locationName: locationName,
                contents: []
            )
            
            // 获取 Contents 子集合的数据
            let contentsRef = treasureRef.collection("Contents")
            contentsRef.getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "内容集合不存在"])))
                    return
                }
                
                // 遍历子集合并解析内容
                let contents: [TreasureContent] = documents.compactMap { document in
                    let data = document.data()
                    guard let typeString = data["type"] as? String,
                          let content = data["content"] as? String,
                          let index = data["index"] as? Int else {
                        return nil
                    }
                    let type = ContentType(rawValue: typeString) ?? .text
                    return TreasureContent(id: document.documentID, type: type, content: content, index: index)
                }
                
                // 将获取的内容赋值给 Treasure 对象
                treasure.contents = contents
                completion(.success(treasure))
            }
        }
    }
    
    // MARK: - 查找附近的宝藏
    func fetchAllTreasuresNear(userID: String, minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping (Result<[TreasureSummary], Error>) -> Void) {
        // 首先获取用户自己的所有宝藏（包括公开和私人）
        fetchUserTreasuresNear(userID: userID, minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { userResult in
            switch userResult {
            case .success(let userTreasures):
            var allTreasures = userTreasures
                
                // 查询其他用户的公开宝藏
                let publicTreasuresQuery = self.db.collectionGroup("Treasures")
                    .whereField("isPublic", isEqualTo: true)  // 只查询公开的宝藏
                    .whereField("userID", isNotEqualTo: userID)  // 排除当前用户的宝藏
                    .whereField("latitude", isGreaterThanOrEqualTo: minLat)
                    .whereField("latitude", isLessThanOrEqualTo: maxLat)
                    .whereField("longitude", isGreaterThanOrEqualTo: minLng)
                    .whereField("longitude", isLessThanOrEqualTo: maxLng)

                publicTreasuresQuery.getDocuments { snapshot, error in
                    if let error = error {
                        // 如果公开宝藏查询失败，仍然返回用户自己的宝藏
                        completion(.success(allTreasures))
                    } else {
                        let publicTreasures = snapshot?.documents.compactMap { document -> TreasureSummary? in
                            let data = document.data()
                            guard let latitude = data["latitude"] as? Double,
                                  let longitude = data["longitude"] as? Double else {
                                return nil
                            }
                            let treasureID = document.documentID
                            return TreasureSummary(id: treasureID, latitude: latitude, longitude: longitude)
                        } ?? []

                        // 合并用户自己的宝藏和其他用户的公开宝藏
                        allTreasures.append(contentsOf: publicTreasures)

                        // 返回去重后的结果（如果需要）
                        completion(.success(allTreasures))
                    }
                }
            case .failure(let error):
                completion(.failure(error))  // 用户宝藏查询失败时返回错误
            }
        }
    }

    // 查询用户自己的宝藏
    func fetchUserTreasuresNear(userID: String, minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping (Result<[TreasureSummary], Error>) -> Void) {
        // 在用户的 "Treasures" 子集合中按经纬度过滤
        let userTreasuresQuery = db.collection("Users").document(userID).collection("Treasures")
            .whereField("latitude", isGreaterThanOrEqualTo: minLat)
            .whereField("latitude", isLessThanOrEqualTo: maxLat)
            .whereField("longitude", isGreaterThanOrEqualTo: minLng)
            .whereField("longitude", isLessThanOrEqualTo: maxLng)
        
        userTreasuresQuery.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let treasures = snapshot?.documents.compactMap { document -> TreasureSummary? in
                    let data = document.data()
                    guard let latitude = data["latitude"] as? Double,
                          let longitude = data["longitude"] as? Double else {
                        return nil
                    }
                    let treasureID = document.documentID
                    return TreasureSummary(id: treasureID, latitude: latitude, longitude: longitude)
                }
                completion(.success(treasures ?? []))
            }
        }
    }
        
        // 将 Firestore document 转换为 TreasureSummary
        func documentToTreasureSummary(_ document: DocumentSnapshot) -> TreasureSummary? {
            let data = document.data()
            guard let latitude = data?["latitude"] as? Double,
                  let longitude = data?["longitude"] as? Double else {
                return nil
            }
            return TreasureSummary(id: document.documentID, latitude: latitude, longitude: longitude)
        }
        
        // MARK: - 類別處理
        func loadCategories(userID: String, defaultCategories: [String], completion: @escaping ([String]) -> Void) {
            let userDocument = db.collection("Users").document(userID)
            
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
        
         func setDefaultCategories(userID: String, defaultCategories: [String], completion: @escaping () -> Void) {
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
        
        // 更新用户类别
        func addCategory(userID: String, category: String, completion: @escaping (Bool) -> Void) {
            let userDocument = db.collection("Users").document(userID)
            userDocument.updateData([
                "category": FieldValue.arrayUnion([category])
            ]) { error in
                completion(error == nil)
            }
        }
        
        func deleteCategory(userID: String, category: String, completion: @escaping (Bool) -> Void) {
            let userDocument = db.collection("Users").document(userID)
            userDocument.updateData([
                "category": FieldValue.arrayRemove([category])
            ]) { error in
                completion(error == nil)
            }
        }
    
    func deleteCategoryAndTreasures(userID: String, category: String, completion: @escaping (Bool) -> Void) {
        // 首先查詢並刪除該類別下的所有寶藏
        fetchTreasuresForCategory(userID: userID, category: category) { result in
            switch result {
            case .success(let treasures):
                let dispatchGroup = DispatchGroup()
                
                for treasure in treasures {
                                guard let treasureID = treasure.id else {
                                    print("無法刪除，寶藏 ID 為 nil")
                                    dispatchGroup.leave()
                                    continue
                                }
                                
                                dispatchGroup.enter()
                                self.deleteTreasure(userID: userID, treasureID: treasureID) { success in
                                    if success {
                                        print("成功刪除寶藏: \(treasureID)")
                                    } else {
                                        print("刪除寶藏失敗: \(treasureID)")
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                
                dispatchGroup.notify(queue: .main) {
                    // 當所有寶藏刪除完成後，刪除該類別
                    self.deleteCategory(userID: userID, category: category, completion: completion)
                }
                
            case .failure(let error):
                print("加載寶藏失敗: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    func deleteTreasure(userID: String, treasureID: String, completion: @escaping (Bool) -> Void) {
        let treasureRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)
        treasureRef.delete { error in
            if let error = error {
                print("刪除寶藏錯誤: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    func updateTreasureFields(userID: String, treasureID: String, category: String, isPublic: Bool) {
        let documentRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)
        documentRef.updateData([
            "category": category,
            "isPublic": isPublic
        ]) { error in
            if let error = error {
                print("Error updating treasure: \(error)")
            } else {
                print("Treasure successfully updated")
                print("更新宝藏，路径：\(documentRef.path)")
                    print("新类别：\(category)，isPublic：\(isPublic)")
            }
        }
    }

    func deleteSingleTreasure(userID: String, treasureID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let treasureRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)
        treasureRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    
    func updateCategoryNameAndTreasures(userID: String, oldName: String, newName: String, completion: @escaping (Bool) -> Void) {
        // 先更新 Firestore 中的類別名稱
        updateCategoryName(userID: userID, oldName: oldName, newName: newName) { success in
            if success {
                // 類別名稱更新成功後，再更新所有屬於該類別的寶藏
                self.fetchTreasuresForCategory(userID: userID, category: oldName) { result in
                    switch result {
                    case .success(let treasures):
                        let dispatchGroup = DispatchGroup()
                        
                        for treasure in treasures {
                            guard let treasureID = treasure.id else {
                                print("無法更新，寶藏 ID 為 nil")
                                dispatchGroup.leave()
                                continue
                            }
                            
                            dispatchGroup.enter()
                            let treasureRef = self.db.collection("Users").document(userID).collection("Treasures").document(treasureID)
                            treasureRef.updateData(["category": newName]) { error in
                                if let error = error {
                                    print("更新寶藏類別名稱失敗: \(error.localizedDescription)")
                                }
                                dispatchGroup.leave()
                            }
                        }
                        
                        dispatchGroup.notify(queue: .main) {
                            completion(true)
                        }
                        
                    case .failure(let error):
                        print("加載寶藏失敗: \(error.localizedDescription)")
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
        }
    }

    
    func updateCategoryName(userID: String, oldName: String, newName: String, completion: @escaping (Bool) -> Void) {
        let userDocRef = db.collection("Users").document(userID)
        userDocRef.updateData([
            "category": FieldValue.arrayRemove([oldName])  // 先刪除舊名稱
        ]) { error in
            if error == nil {
                userDocRef.updateData([
                    "category": FieldValue.arrayUnion([newName])  // 再添加新名稱
                ]) { error in
                    completion(error == nil)
                }
            } else {
                completion(false)
            }
        }
    }

    func fetchTreasuresForCategory(userID: String, category: String, completion: @escaping (Result<[Treasure], Error>) -> Void) {
        let treasuresCollection = db.collection("Users").document(userID).collection("Treasures")
        
        // 查詢符合該類別的所有寶藏
        treasuresCollection.whereField("category", isEqualTo: category).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "沒有找到寶藏"])))
                return
            }
            
            // Dispatch Group 用於處理所有寶藏的加載，包含其 contents
            let dispatchGroup = DispatchGroup()
            var treasures: [Treasure] = []
            
            for document in documents {
                let data = document.data()
                guard let category = data["category"] as? String,
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let locationName = data["locationName"] as? String,
                      let isPublic = data["isPublic"] as? Bool,
                      let createdTime = data["createdTime"] as? Timestamp else {
                    continue
                }
                
                // 生成初始寶藏對象（不包含 contents）
                var treasure = Treasure(
                    id: document.documentID,
                    category: category,
                    createdTime: createdTime.dateValue(),
                    isPublic: isPublic,
                    latitude: latitude,
                    longitude: longitude,
                    locationName: locationName,
                    contents: []  // 這裡先初始化空的 contents
                )
                
                // 開始獲取這個寶藏的 contents
                dispatchGroup.enter()
                let contentsRef = treasuresCollection.document(document.documentID).collection("Contents")
                contentsRef.getDocuments { contentSnapshot, contentError in
                    if let contentError = contentError {
                        print("Error fetching contents: \(contentError.localizedDescription)")
                    } else if let contentDocuments = contentSnapshot?.documents {
                        treasure.contents = contentDocuments.compactMap { contentDoc in
                            let contentData = contentDoc.data()
                            guard let typeString = contentData["type"] as? String,
                                  let content = contentData["content"] as? String,
                                  let index = contentData["index"] as? Int else {
                                return nil
                            }
                            let type = ContentType(rawValue: typeString) ?? .text
                            return TreasureContent(id: contentDoc.documentID, type: type, content: content, index: index)
                        }
                    }
                    treasures.append(treasure)  // 添加寶藏（包含 contents）
                    dispatchGroup.leave()
                }
            }
            
            // 當所有寶藏及其內容加載完成後，調用 completion 回調
            dispatchGroup.notify(queue: .main) {
                completion(.success(treasures))
            }
        }
    }

    
    func fetchAllTreasures(userID: String, completion: @escaping (Result<[Treasure], Error>) -> Void) {
        let treasuresCollection = db.collection("Users").document(userID).collection("Treasures")
        
        treasuresCollection.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "沒有找到寶藏"])))
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var treasures: [Treasure] = []
            
            for document in documents {
                let data = document.data()
                guard let category = data["category"] as? String,
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let locationName = data["locationName"] as? String,
                      let isPublic = data["isPublic"] as? Bool,
                      let createdTime = data["createdTime"] as? Timestamp else {
                    continue
                }
                
                var treasure = Treasure(
                    id: document.documentID,
                    category: category,
                    createdTime: createdTime.dateValue(),
                    isPublic: isPublic,
                    latitude: latitude,
                    longitude: longitude,
                    locationName: locationName,
                    contents: []  // 初始化為空
                )
                
                dispatchGroup.enter()
                let contentsRef = treasuresCollection.document(document.documentID).collection("Contents")
                contentsRef.getDocuments { contentSnapshot, contentError in
                    if let contentError = contentError {
                        print("Error fetching contents: \(contentError.localizedDescription)")
                    } else if let contentDocuments = contentSnapshot?.documents {
                        treasure.contents = contentDocuments.compactMap { contentDoc in
                            let contentData = contentDoc.data()
                            guard let typeString = contentData["type"] as? String,
                                  let content = contentData["content"] as? String,
                                  let index = contentData["index"] as? Int else {
                                return nil
                            }
                            let type = ContentType(rawValue: typeString) ?? .text
                            return TreasureContent(id: contentDoc.documentID, type: type, content: content, index: index)
                        }
                    }
                    treasures.append(treasure)
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(.success(treasures))
            }
        }
    }
    
}
