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
    
    // 保存新宝藏及其内容
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
    
    // 保存宝藏内容
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
    
    // 将宝藏ID加入用户的宝藏列表
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
    
    // 查询所有宝藏，包括用户自己的和其他用户的公开宝藏
    func fetchAllTreasuresNear(userID: String, minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping (Result<[TreasureSummary], Error>) -> Void) {
        // 首先获取用户自己的宝藏
        fetchUserTreasuresNear(userID: userID, minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { userResult in
            switch userResult {
            case .success(let userTreasures):
                var allTreasures = userTreasures
                
                // 查询其他用户的公开宝藏
                let publicTreasuresQuery = self.db.collectionGroup("Treasures")
                    .whereField("isPublic", isEqualTo: true)
                    .whereField("latitude", isGreaterThanOrEqualTo: minLat)
                    .whereField("latitude", isLessThanOrEqualTo: maxLat)
                    .whereField("longitude", isGreaterThanOrEqualTo: minLng)
                    .whereField("longitude", isLessThanOrEqualTo: maxLng)
                // 确保字段名是否正确（例如 'ownerID'，而非 'userID'）
                    .whereField("ownerID", isNotEqualTo: userID)
                
                // 获取其他用户的公开宝藏
                publicTreasuresQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        let publicTreasures = snapshot?.documents.compactMap { document -> TreasureSummary? in
                            let data = document.data()
                            guard let latitude = data["latitude"] as? Double,
                                  let longitude = data["longitude"] as? Double else {
                                return nil
                            }
                            let treasureID = document.documentID
                            return TreasureSummary(id: treasureID, latitude: latitude, longitude: longitude)
                        }
                        // 合并用户自己的宝藏和公开宝藏
                        allTreasures.append(contentsOf: publicTreasures ?? [])
                        completion(.success(allTreasures))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
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
        
        // MARK: - 类别处理
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
    
}
