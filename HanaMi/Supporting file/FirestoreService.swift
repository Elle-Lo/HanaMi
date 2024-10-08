import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import CoreLocation

class FirestoreService {
    private let db = Firestore.firestore()
    
    func checkUserExists(uid: String, completion: @escaping (Bool) -> Void) {
        let docRef = db.collection("Users").document(uid)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                completion(true) // 用戶已經存在
            } else {
                completion(false) // 用戶不存在
            }
        }
    }
    
    func createUserInFirestore(uid: String, name: String, email: String) {
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "treasureList": [],
            "categories": [],
            "characterName": "Hanami",
            "userImage": "",
            "backgroundImage": "",
            "collectionTreasureList": []
        ]
        
        db.collection("Users").document(uid).setData(userData) { error in
            if let error = error {
                print("Error creating user in Firestore: \(error.localizedDescription)")
            } else {
                print("User document successfully created in Firestore!")
            }
        }
    }
    
    func deleteUserAccount(uid: String, completion: @escaping (Bool) -> Void) {
            let userDocRef = db.collection("Users").document(uid)
            
            userDocRef.delete { error in
                if let error = error {
                    print("刪除 Firestore 中的用戶數據失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Firestore 中的用戶數據已刪除")
                    completion(true)
                }
            }
        }
    
    func fetchUserData(uid: String, completion: @escaping (String?, String?, String?, String?) -> Void) {
        let docRef = db.collection("Users").document(uid)
        docRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(nil, nil, nil, nil)
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                let name = snapshot.get("name") as? String
                let profileImageUrl = snapshot.get("userImage") as? String
                let backgroundImageUrl = snapshot.get("backgroundImage") as? String
                let characterName = snapshot.get("characterName") as? String // 新增 characterName 的讀取
                completion(name, profileImageUrl, backgroundImageUrl, characterName)
            } else {
                completion(nil, nil, nil, nil)
            }
        }
    }

    
    func fetchUserBackgroundImage(uid: String, completion: @escaping (String?) -> Void) {
        let docRef = db.collection("Users").document(uid)
        docRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching background image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                let imageUrl = snapshot.get("backgroundImage") as? String
                completion(imageUrl)
            } else {
                completion(nil)
            }
        }
    }
    
    // 更新 Firestore 中的用戶名稱
    func updateUserName(uid: String, name: String) {
        let docRef = db.collection("Users").document(uid)
        docRef.updateData(["name": name]) { error in
            if let error = error {
                print("Error updating user name: \(error.localizedDescription)")
            } else {
                print("User name successfully updated in Firestore!")
            }
        }
    }
    
    func updateUserCharacterName(uid: String, characterName: String) {
        let docRef = db.collection("Users").document(uid)

        docRef.updateData(["characterName": characterName]) { error in
            if let error = error {
                print("Error updating character name: \(error.localizedDescription)")
            } else {
                print("Character name successfully updated")
            }
        }
    }
    
    // 更新用戶的背景圖片 URL
    func updateUserBackgroundImage(uid: String, imageUrl: String) {
        let docRef = db.collection("Users").document(uid)
        docRef.updateData(["backgroundImage": imageUrl]) { error in
            if let error = error {
                print("Error updating background image: \(error.localizedDescription)")
            } else {
                print("Background image successfully updated in Firestore!")
            }
        }
    }
    
    // 更新用戶頭像 URL
    func updateUserProfileImage(uid: String, imageUrl: String) {
        let docRef = db.collection("Users").document(uid)
        docRef.updateData(["userImage": imageUrl]) { error in
            if let error = error {
                print("Error updating user image: \(error.localizedDescription)")
            } else {
                print("User profile image successfully updated in Firestore!")
            }
        }
    }
    // 刪除用戶頭像 URL 並刪除 Firebase Storage 上的圖片
    func removeUserProfileImage(uid: String, currentImageUrl: String, completion: @escaping (Bool) -> Void) {
        // 確認圖片 URL 不為空
        guard !currentImageUrl.isEmpty else {
            // 如果沒有圖片，直接從 Firestore 中刪除連結
            updateUserProfileImage(uid: uid, imageUrl: "")
            completion(true)
            return
        }

        // 取得 Firebase Storage 的圖片參考
        let storageRef = Storage.storage().reference(forURL: currentImageUrl)
        
        // 刪除 Firebase Storage 上的圖片
        storageRef.delete { error in
            if let error = error {
                print("Error deleting image from Firebase Storage: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Image successfully deleted from Firebase Storage.")
                
                // 成功刪除圖片後，更新 Firestore，將圖片 URL 設置為空
                self.updateUserProfileImage(uid: uid, imageUrl: "")
                completion(true)
            }
        }
    }
    
    func removeUserBackgroundImage(uid: String, imageUrl: String, completion: @escaping (Bool) -> Void) {
        let storageRef = Storage.storage().reference(forURL: imageUrl) // 透過 URL 獲取 Firebase Storage 中的參考

        // 刪除 Firebase Storage 中的圖片
        storageRef.delete { error in
            if let error = error {
                print("Error deleting background image from Firebase Storage: \(error.localizedDescription)")
                completion(false)
            } else {
                // 圖片刪除成功，更新 Firestore 中的 URL
                let docRef = self.db.collection("Users").document(uid)
                docRef.updateData(["backgroundImage": ""]) { error in
                    if let error = error {
                        print("Error updating Firestore background image: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Background image successfully removed from Firestore and Storage!")
                        completion(true)
                    }
                }
            }
        }
    }


    
    // MARK: - Treasure Handling
    
    // 随机获取用户保存的宝藏（最多三笔）
    func fetchRandomTreasures(userID: String, completion: @escaping (Result<[Treasure], Error>) -> Void) {
        let userDocument = db.collection("Users").document(userID)
        
        userDocument.getDocument { [weak self] (document, error) in
            guard let self = self, let document = document, document.exists else {
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "文黨不存在或寶藏列表為空"])))
                return
            }
            
            guard let treasureList = document.data()?["treasureList"] as? [String], !treasureList.isEmpty else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "寶藏列表為空"])))
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
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有找到寶藏"])))
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
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "寶藏不存在"])))
                return
            }
            
            let data = document.data() ?? [:]
            
            guard let category = data["category"] as? String,
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double,
                  let locationName = data["locationName"] as? String,
                  let isPublic = data["isPublic"] as? Bool,
                  let timestamp = data["createdTime"] as? Timestamp else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "數據格式不匹配"])))
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
    
    func fetchAllTreasuresNear(minLat: Double, maxLat: Double, maxLng: Double, minLng: Double, currentUserID: String, completion: @escaping (Result<[TreasureSummary], Error>) -> Void) {
        let publicTreasuresQuery = db.collectionGroup("Treasures")
            .whereField("isPublic", isEqualTo: true) // 只抓取公開寶藏
            .whereField("latitude", isGreaterThanOrEqualTo: minLat)
            .whereField("latitude", isLessThanOrEqualTo: maxLat)
            .whereField("longitude", isGreaterThanOrEqualTo: minLng)
            .whereField("longitude", isLessThanOrEqualTo: maxLng)

        publicTreasuresQuery.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let treasures = snapshot?.documents.compactMap { document -> TreasureSummary? in
                    let data = document.data()
                    guard let latitude = data["latitude"] as? Double,
                          let longitude = data["longitude"] as? Double,
                          let userID = data["userID"] as? String else {
                        return nil
                    }
                    
                    // 手動過濾掉當前用戶的寶藏
                    if userID == currentUserID {
                        return nil
                    }

                    let treasureID = document.documentID
                    return TreasureSummary(id: treasureID, latitude: latitude, longitude: longitude, userID: userID)
                } ?? []
                completion(.success(treasures))
            }
        }
    }

    
    
    // 查询用户自己的宝藏
    func fetchUserTreasuresNear(userID: String, minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping (Result<[TreasureSummary], Error>) -> Void) {
        
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
                    return TreasureSummary(id: treasureID, latitude: latitude, longitude: longitude, userID: userID)
                }
                completion(.success(treasures ?? []))
            }
        }
    }
    
    // 将 Firestore document 转换为 TreasureSummary
    func documentToTreasureSummary(_ document: DocumentSnapshot) -> TreasureSummary? {
        let data = document.data()
        guard let latitude = data?["latitude"] as? Double,
              let longitude = data?["longitude"] as? Double,
              let userID = data?["userID"] as? String else {
            return nil
        }
        
        let treasureID = document.documentID // 从 DocumentSnapshot 获取 documentID 作为 treasureID
        return TreasureSummary(id: treasureID, latitude: latitude, longitude: longitude, userID: userID)
    }
    
    //將寶藏id加到收藏寶藏清單
    func addTreasureToFavorites(userID: String, treasureID: String, completion: @escaping (Result<Void, Error>) -> Void) {
            let userDocRef = db.collection("Users").document(userID)

            userDocRef.updateData([
                "collectionTreasureList": FieldValue.arrayUnion([treasureID])
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    
    // MARK: - 類別處理
    func loadCategories(userID: String, completion: @escaping ([String]) -> Void) {
        let defaultCategories = ["Creative", "Energetic", "Happy"]  // 設置預設的類別
        let userDocument = db.collection("Users").document(userID)
        
        userDocument.getDocument { documentSnapshot, error in
            if let error = error {
                print("Error fetching Firestore document: \(error)")
                completion(defaultCategories)  // 如果加載出錯，返回預設類別
            } else if let document = documentSnapshot, document.exists {
                if let categoryArray = document.data()?["categories"] as? [String], !categoryArray.isEmpty {
                    completion(categoryArray)  // 加載到已有類別
                } else {
                    // 如果 categories 不存在或為空，設置預設類別
                    self.setDefaultCategories(userID: userID, defaultCategories: defaultCategories) {
                        completion(defaultCategories)  // 返回預設類別
                    }
                }
            } else {
                // 文檔不存在時，設置預設類別
                self.setDefaultCategories(userID: userID, defaultCategories: defaultCategories) {
                    completion(defaultCategories)  // 返回預設類別
                }
            }
        }
    }
    
    func setDefaultCategories(userID: String, defaultCategories: [String], completion: @escaping () -> Void) {
        let userDocument = db.collection("Users").document(userID)
        userDocument.updateData([
            "categories": defaultCategories  // 正確寫入 categories 字段
        ]) { error in
            if let error = error {
                print("Error setting default categories: \(error)")
            } else {
                print("Default categories set in Firestore")
            }
            completion()  // 完成回調
        }
    }
    
    
    // 更新用户类别
    func addCategory(userID: String, category: String, completion: @escaping (Bool) -> Void) {
        let userDocument = db.collection("Users").document(userID)
        userDocument.updateData([
            "categories": FieldValue.arrayUnion([category])
        ]) { error in
            completion(error == nil)
        }
    }
    
    //        func deleteCategory(userID: String, category: String, completion: @escaping (Bool) -> Void) {
    //            let userDocument = db.collection("Users").document(userID)
    //            userDocument.updateData([
    //                "categories": FieldValue.arrayRemove([category])
    //            ]) { error in
    //                completion(error == nil)
    //            }
    //        }
    
    func deleteCategoryAndTreasures(userID: String, category: String, completion: @escaping (Bool) -> Void) {
        // 首先查詢該類別下的所有寶藏
        fetchTreasuresForCategory(userID: userID, category: category) { result in
            switch result {
            case .success(let treasures):
                let dispatchGroup = DispatchGroup()
                
                for treasure in treasures {
                    guard let treasureID = treasure.id else {
                        print("無法刪除，寶藏 ID 為 nil")
                        continue
                    }
                    
                    // 刪除寶藏及其內容，並從 treasureList 中移除
                    dispatchGroup.enter()
                    self.deleteTreasureAndRemoveFromList(userID: userID, treasureID: treasureID) { success in
                        if success {
                            print("成功刪除寶藏: \(treasureID)")
                        } else {
                            print("刪除寶藏失敗: \(treasureID)")
                        }
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    // 當所有寶藏刪除完成後，直接在這裡刪除類別
                    let userDocRef = self.db.collection("Users").document(userID)
                    userDocRef.updateData([
                        "categories": FieldValue.arrayRemove([category])
                    ]) { error in
                        if let error = error {
                            print("類別刪除失敗: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            print("類別和所有寶藏刪除成功")
                            completion(true)
                        }
                    }
                }
                
            case .failure(let error):
                print("加載寶藏失敗: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    
    func deleteTreasureAndRemoveFromList(userID: String, treasureID: String, completion: @escaping (Bool) -> Void) {
        let treasureRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)
        
        // 刪除寶藏文檔
        treasureRef.delete { error in
            if let error = error {
                print("刪除寶藏錯誤: \(error.localizedDescription)")
                completion(false)
            } else {
                // 從 treasureList 中移除寶藏 ID
                let userDocRef = self.db.collection("Users").document(userID)
                userDocRef.updateData([
                    "treasureList": FieldValue.arrayRemove([treasureID])
                ]) { error in
                    if let error = error {
                        print("從 treasureList 移除寶藏 ID 失敗: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("成功從 treasureList 移除寶藏 ID")
                        completion(true)
                    }
                }
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
    func updateTreasureFields(userID: String, treasureID: String, category: String, isPublic: Bool, completion: @escaping (Bool) -> Void) {
        let documentRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)
        documentRef.updateData([
            "category": category,
            "isPublic": isPublic
        ]) { error in
            if let error = error {
                print("Error updating treasure: \(error)")
                completion(false)
            } else {
                print("Treasure successfully updated")
                completion(true)
            }
        }
    }
    
    
    func deleteSingleTreasure(userID: String, treasureID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let treasureRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)
        
        // 首先刪除寶藏文檔
        treasureRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // 刪除成功後，從 treasureList 中移除該 treasureID
                let userDocRef = self.db.collection("Users").document(userID)
                userDocRef.updateData([
                    "treasureList": FieldValue.arrayRemove([treasureID])
                ]) { error in
                    if let error = error {
                        print("從 treasureList 移除 treasureID 失敗: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("成功刪除寶藏並從 treasureList 移除")
                        completion(.success(()))
                    }
                }
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
                            // 更新完所有寶藏後，強制重新加載新的類別資料
                            self.fetchTreasuresForCategory(userID: userID, category: newName) { result in
                                switch result {
                                case .success(let updatedTreasures):
                                    print("寶藏名稱和類別成功更新")
                                    // 在這裡你可以直接觸發 UI 刷新，例如通過回調或者發送通知來更新 UI
                                    // 例如：self.delegate?.didUpdateCategory(newName: newName, treasures: updatedTreasures)
                                    completion(true)
                                case .failure(let error):
                                    print("更新後加載寶藏失敗: \(error.localizedDescription)")
                                    completion(false)
                                }
                            }
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
            "categories": FieldValue.arrayRemove([oldName])  // 先刪除舊名稱
        ]) { error in
            if error == nil {
                userDocRef.updateData([
                    "categories": FieldValue.arrayUnion([newName])  // 再添加新名稱
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
