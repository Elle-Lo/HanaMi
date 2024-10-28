import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import CoreLocation

class FirestoreService {
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    
    private var cachedTreasures: [Treasure] = []
    
    func checkUserExists(uid: String, completion: @escaping (Bool) -> Void) {
        let docRef = db.collection("Users").document(uid)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                completion(true)
            } else {
                completion(false)
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
            "collectionTreasureList": [],
            "blockList": [],
            "wasBlockedByList": []
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
                let characterName = snapshot.get("characterName") as? String
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

    func removeUserProfileImage(uid: String, currentImageUrl: String, completion: @escaping (Bool) -> Void) {
       
        guard !currentImageUrl.isEmpty else {
            updateUserProfileImage(uid: uid, imageUrl: "")
            completion(true)
            return
        }
        
        let storageRef = Storage.storage().reference(forURL: currentImageUrl)
        
        storageRef.delete { error in
            if let error = error {
                print("Error deleting image from Firebase Storage: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Image successfully deleted from Firebase Storage.")
                
                self.updateUserProfileImage(uid: uid, imageUrl: "")
                completion(true)
            }
        }
    }
    
    func removeUserBackgroundImage(uid: String, imageUrl: String, completion: @escaping (Bool) -> Void) {
        let storageRef = Storage.storage().reference(forURL: imageUrl)
        
        storageRef.delete { error in
            if let error = error {
                print("Error deleting background image from Firebase Storage: \(error.localizedDescription)")
                completion(false)
            } else {
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
    
    func saveTreasure(userID: String, coordinate: CLLocationCoordinate2D, locationName: String, category: String, isPublic: Bool, contents: [TreasureContent], completion: @escaping (Result<Void, Error>) -> Void) {
     
        let treasureID = db.collection("Users").document(userID).collection("Treasures").document().documentID
        
        let treasureData: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "locationName": locationName,
            "category": category,
            "isPublic": isPublic,
            "createdTime": Timestamp(),
            "userID": userID
        ]
        
        let userTreasureRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)
        let allTreasureRef = db.collection("AllTreasures").document(treasureID)
        let dispatchGroup = DispatchGroup()
        
        var errorOccurred: Error?
        
        dispatchGroup.enter()
        userTreasureRef.setData(treasureData) { error in
            if let error = error {
                errorOccurred = error
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        allTreasureRef.setData(treasureData) { error in
            if let error = error {
                errorOccurred = error
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = errorOccurred {
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
    
    func saveTreasureContents(treasureID: String, userID: String, contents: [TreasureContent], completion: @escaping (Result<Void, Error>) -> Void) {
        let userContentCollectionRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID).collection("Contents")
        let allContentCollectionRef = db.collection("AllTreasures").document(treasureID).collection("Contents")
        
        let dispatchGroup = DispatchGroup()
        var errorOccurred: Error?
        
        for content in contents {
            let contentID = content.id
            
            dispatchGroup.enter()
            let userContentRef = userContentCollectionRef.document(contentID)
            
            do {
                try userContentRef.setData(from: content) { error in
                    if let error = error {
                        errorOccurred = error
                    }
                    dispatchGroup.leave()
                }
            } catch let error {
                errorOccurred = error
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            let allContentRef = allContentCollectionRef.document(contentID)
            
            do {
                try allContentRef.setData(from: content) { error in
                    if let error = error {
                        errorOccurred = error
                    }
                    dispatchGroup.leave()
                }
            } catch let error {
                errorOccurred = error
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = errorOccurred {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
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
                  let timestamp = data["createdTime"] as? Timestamp,
                  let userID = data["userID"] as? String
            else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "數據格式不匹配"])))
                return
            }
            
            var treasure = Treasure(
                id: treasureID,
                category: category,
                createdTime: timestamp.dateValue(),
                isPublic: isPublic,
                latitude: latitude,
                longitude: longitude,
                locationName: locationName,
                contents: [],
                userID: userID
            )
            
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
                
                treasure.contents = contents
                completion(.success(treasure))
            }
        }
    }
    
    func fetchAllTreasuresNear(
        minLat: Double,
        maxLat: Double,
        maxLng: Double,
        minLng: Double,
        currentUserID: String,
        completion: @escaping (Result<[TreasureSummary], Error>) -> Void
    ) {
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(currentUserID)

        userRef.getDocument { snapshot, error in
                guard let data = snapshot?.data() else {
                    print("無法取得使用者資料")
                    completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "無法取得使用者資料"])))
                    return
                }

                let blockList = data["blockList"] as? [String] ?? []
                let wasBlockedByList = data["wasBlockedByList"] as? [String] ?? []

                print("封鎖名單：\(blockList)")
                print("被封鎖名單：\(wasBlockedByList)")

                self.queryPublicTreasures(
                    minLat: minLat,
                    maxLat: maxLat,
                    minLng: minLng,
                    maxLng: maxLng,
                    blockList: blockList,
                    wasBlockedByList: wasBlockedByList,
                    currentUserID: currentUserID,
                    completion: completion
                )
            }
    }

    private func queryPublicTreasures(
        minLat: Double,
        maxLat: Double,
        minLng: Double,
        maxLng: Double,
        blockList: [String],
        wasBlockedByList: [String],
        currentUserID: String,
        completion: @escaping (Result<[TreasureSummary], Error>) -> Void
    ) {
        let db = Firestore.firestore()

        let publicTreasuresQuery = db.collection("AllTreasures")
            .whereField("isPublic", isEqualTo: true)
            .whereField("latitude", isGreaterThanOrEqualTo: minLat)
            .whereField("latitude", isLessThanOrEqualTo: maxLat)
            .whereField("longitude", isGreaterThanOrEqualTo: minLng)
            .whereField("longitude", isLessThanOrEqualTo: maxLng)

        publicTreasuresQuery.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let treasures = snapshot?.documents.compactMap { document -> TreasureSummary? in
                let data = document.data()
                guard let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let userID = data["userID"] as? String else {
                    return nil
                }
                
                if blockList.contains(userID) || wasBlockedByList.contains(userID) {
                    print("排除 \(userID) 的寶藏，因為封鎖條件符合")
                    return nil
                }
                
                if userID == currentUserID {
                    print("排除目前使用者自己的寶藏")
                    return nil
                }

                let treasureID = document.documentID
                return TreasureSummary(id: treasureID, latitude: latitude, longitude: longitude, userID: userID)
            } ?? []

            completion(.success(treasures))
        }
    }

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
    
    func documentToTreasureSummary(_ document: DocumentSnapshot) -> TreasureSummary? {
        let data = document.data()
        guard let latitude = data?["latitude"] as? Double,
              let longitude = data?["longitude"] as? Double,
              let userID = data?["userID"] as? String else {
            return nil
        }
        
        let treasureID = document.documentID
        return TreasureSummary(id: treasureID, latitude: latitude, longitude: longitude, userID: userID)
    }
    
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
    
    func clearCache() {
        self.cachedTreasures.removeAll()
        self.lastDocument = nil
    }
    
    func fetchFavoriteTreasures(userID: String, completion: @escaping (Result<[Treasure], Error>) -> Void) {
        db.collection("Users").document(userID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, let data = document.data(), let treasureIDs = data["collectionTreasureList"] as? [String] {
                var treasures: [Treasure] = []
                let dispatchGroup = DispatchGroup()
                
                for treasureID in treasureIDs {
                    dispatchGroup.enter()
                    self.fetchTreasureFromAllTreasures(treasureID: treasureID) { result in
                        switch result {
                        case .success(let treasure):
                            treasures.append(treasure)
                        case .failure(let error):
                            print("Error fetching treasure with ID \(treasureID): \(error.localizedDescription)")
                        }
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    completion(.success(treasures))
                }
            } else {
                completion(.success([]))
            }
        }
    }
    
    func removeTreasureFromFavorites(userID: String, treasureID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userDocRef = db.collection("Users").document(userID)
        
        userDocRef.updateData([
            "collectionTreasureList": FieldValue.arrayRemove([treasureID])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchTreasureFromAllTreasures(treasureID: String, completion: @escaping (Result<Treasure, Error>) -> Void) {
        let treasureRef = db.collection("AllTreasures").document(treasureID)
        
        print("Fetching treasure with ID: \(treasureID)")
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
                  let timestamp = data["createdTime"] as? Timestamp,
                  let userID = data["userID"] as? String
            else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "數據格式不匹配"])))
                return
            }
           
            var treasure = Treasure(
                id: treasureID,
                category: category,
                createdTime: timestamp.dateValue(),
                isPublic: isPublic,
                latitude: latitude,
                longitude: longitude,
                locationName: locationName,
                contents: [],
                userID: userID
            )
            
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
                
                treasure.contents = contents
                completion(.success(treasure))
            }
        }
    }
    
    // MARK: - 類別處理
    func loadCategories(userID: String, completion: @escaping ([String]) -> Void) {
        let defaultCategories = ["Creative", "Energetic", "Happy"]
        let userDocument = db.collection("Users").document(userID)
        
        userDocument.getDocument { documentSnapshot, error in
            if let error = error {
                print("Error fetching Firestore document: \(error)")
                completion(defaultCategories)
            } else if let document = documentSnapshot, document.exists {
                if let categoryArray = document.data()?["categories"] as? [String], !categoryArray.isEmpty {
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
        userDocument.updateData([
            "categories": defaultCategories
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
            "categories": FieldValue.arrayUnion([category])
        ]) { error in
            completion(error == nil)
        }
    }
    
    func deleteCategoryAndTreasures(userID: String, category: String, completion: @escaping (Bool) -> Void) {
        fetchTreasuresForCategory(userID: userID, category: category) { result in
            switch result {
            case .success(let treasures):
                let dispatchGroup = DispatchGroup()
                var hasErrorOccurred = false
                
                for treasure in treasures {
                    guard let treasureID = treasure.id else {
                        print("無法刪除，寶藏 ID 為 nil")
                        continue
                    }
                    
                    dispatchGroup.enter()
                    self.deleteTreasureAndRemoveFromList(userID: userID, treasureID: treasureID) { success in
                        if !success {
                            hasErrorOccurred = true
                        }
                        dispatchGroup.leave()
                    }
                }
     
                dispatchGroup.notify(queue: .main) {
                    if hasErrorOccurred {
                        completion(false)
                        return
                    }
                    
                    let userDocRef = self.db.collection("Users").document(userID)
                    userDocRef.updateData([
                        "categories": FieldValue.arrayRemove([category])
                    ]) { error in
                        if let error = error {
                            print("類別刪除失敗: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            print("類別和所有寶藏成功刪除")
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
        let allTreasureRef = db.collection("AllTreasures").document(treasureID)
        let treasureRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)
        let userDocRef = db.collection("Users").document(userID)
        
        let dispatchGroup = DispatchGroup()
        var hasErrorOccurred = false
        
        dispatchGroup.enter()
        deleteContentsInDocument(treasureRef) { success in
            if success {
                treasureRef.delete { error in
                    if let error = error {
                        print("刪除 Users 集合中的寶藏失敗: \(error.localizedDescription)")
                        hasErrorOccurred = true
                    }
                    dispatchGroup.leave()
                }
            } else {
                hasErrorOccurred = true
                dispatchGroup.leave()
            }
        }

        dispatchGroup.enter()
        userDocRef.updateData([
            "treasureList": FieldValue.arrayRemove([treasureID])
        ]) { error in
            if let error = error {
                print("從 treasureList 移除寶藏 ID 失敗: \(error.localizedDescription)")
                hasErrorOccurred = true
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        deleteContentsInDocument(allTreasureRef) { success in
            if success {
                allTreasureRef.delete { error in
                    if let error = error {
                        print("刪除 AllTreasures 集合中的寶藏失敗: \(error.localizedDescription)")
                        hasErrorOccurred = true
                    }
                    dispatchGroup.leave()
                }
            } else {
                hasErrorOccurred = true
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(!hasErrorOccurred)
        }
    }
    
    func deleteSingleTreasure(userID: String, treasureID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let allContentCollectionRef = db.collection("AllTreasures").document(treasureID)
        let treasureRef = db.collection("Users").document(userID).collection("Treasures").document(treasureID)
        
        let dispatchGroup = DispatchGroup()
        var hasErrorOccurred = false
        
        dispatchGroup.enter()
        deleteContentsInDocument(treasureRef) { success in
            if success {
                treasureRef.delete { error in
                    if let error = error {
                        print("刪除 Users 集合中的寶藏失敗: \(error.localizedDescription)")
                        hasErrorOccurred = true
                    } else {
        
                        self.db.collection("Users").document(userID).updateData([
                            "treasureList": FieldValue.arrayRemove([treasureID])
                        ]) { error in
                            if let error = error {
                                print("從 treasureList 移除 treasureID 失敗: \(error.localizedDescription)")
                                hasErrorOccurred = true
                            }
                        }
                    }
                    dispatchGroup.leave()
                }
            } else {
                hasErrorOccurred = true
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        deleteContentsInDocument(allContentCollectionRef) { success in
            if success {
                allContentCollectionRef.delete { error in
                    if let error = error {
                        print("刪除 AllTreasures 文件失敗: \(error.localizedDescription)")
                        hasErrorOccurred = true
                    }
                    dispatchGroup.leave()
                }
            } else {
                hasErrorOccurred = true
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if hasErrorOccurred {
                completion(.failure(NSError(domain: "刪除失敗", code: -1, userInfo: nil)))
            } else {
                print("成功刪除 Users 和 AllTreasures 中的寶藏")
                completion(.success(()))
            }
        }
    }
    
    private func deleteContentsInDocument(_ documentRef: DocumentReference, completion: @escaping (Bool) -> Void) {
        documentRef.collection("Contents").getDocuments { snapshot, error in
            if let error = error {
                print("獲取內容文件失敗: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var hasErrorOccurred = false
            
            snapshot?.documents.forEach { contentDoc in
                dispatchGroup.enter()
                contentDoc.reference.delete { error in
                    if let error = error {
                        print("刪除內容文件失敗: \(error.localizedDescription)")
                        hasErrorOccurred = true
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(!hasErrorOccurred)
            }
        }
    }
    
    func updateTreasureFields(userID: String, treasureID: String, category: String, isPublic: Bool, completion: @escaping (Bool) -> Void) {
        let allContentCollectionRef = db.collection("AllTreasures").document(treasureID)
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
        
        allContentCollectionRef.updateData([
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
    
    func updateCategoryNameAndTreasures(userID: String, oldName: String, newName: String, completion: @escaping (Bool) -> Void) {

        updateCategoryName(userID: userID, oldName: oldName, newName: newName) { success in
            if success {
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
                            let allContentCollectionRef = self.db.collection("AllTreasures").document(treasureID)
                            
                            let treasureRef = self.db.collection("Users").document(userID).collection("Treasures").document(treasureID)
                            treasureRef.updateData(["category": newName]) { error in
                                if let error = error {
                                    print("更新寶藏類別名稱失敗: \(error.localizedDescription)")
                                }
                                
                                allContentCollectionRef.updateData(["category": newName]) { error in
                                    if let error = error {
                                        print("更新寶藏類別名稱失敗: \(error.localizedDescription)")
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                        }
                        
                        dispatchGroup.notify(queue: .main) {
                            self.fetchTreasuresForCategory(userID: userID, category: newName) { result in
                                switch result {
                                case .success(let updatedTreasures):
                                    print("寶藏名稱和類別成功更新")
                                    
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
            "categories": FieldValue.arrayRemove([oldName])
        ]) { error in
            if error == nil {
                userDocRef.updateData([
                    "categories": FieldValue.arrayUnion([newName])
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
        
        treasuresCollection.whereField("category", isEqualTo: category).getDocuments { snapshot, error in
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
                    contents: [],
                    userID: userID
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
                    contents: [], 
                    userID: userID
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
    
    // MARK: - 檢舉、封鎖
    func reportUser(report: Report, completion: @escaping (Result<Void, Error>) -> Void) {
           let db = Firestore.firestore()
           do {
               try db.collection("Reports").document(report.id).setData(from: report) { error in
                   if let error = error {
                       completion(.failure(error))
                   } else {
                       completion(.success(()))
                   }
               }
           } catch {
               completion(.failure(error))
           }
       }
    
    func blockUser(currentUserID: String, blockedUserID: String, completion: @escaping (Result<Void, Error>) -> Void) {
            let db = Firestore.firestore()
            let batch = db.batch()

            let currentUserRef = db.collection("Users").document(currentUserID)
            batch.updateData([
                "blockList": FieldValue.arrayUnion([blockedUserID])
            ], forDocument: currentUserRef)

            let blockedUserRef = db.collection("Users").document(blockedUserID)
            batch.updateData([
                "wasBlockedByList": FieldValue.arrayUnion([currentUserID])
            ], forDocument: blockedUserRef)

            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    
    func fetchBlockedUsers(for userID: String, completion: @escaping (Result<[(id: String, name: String)], Error>) -> Void) {
            let userRef = db.collection("Users").document(userID)

            userRef.getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = snapshot?.data(),
                      let blockList = data["blockList"] as? [String] else {
                    completion(.success([]))
                    return
                }

                var blockedUsers: [(id: String, name: String)] = []
                let dispatchGroup = DispatchGroup()

                for blockedID in blockList {
                    dispatchGroup.enter()
                    self.db.collection("Users").document(blockedID).getDocument { snapshot, error in
                        if let data = snapshot?.data(), let name = data["name"] as? String {
                            blockedUsers.append((id: blockedID, name: name))
                        }
                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    completion(.success(blockedUsers))
                }
            }
        }
    
    func removeBlock(for userID: String, blockedUserID: String, completion: @escaping (Bool) -> Void) {
            let db = Firestore.firestore()
            let batch = db.batch()

            let userRef = db.collection("Users").document(userID)
           
            let blockedUserRef = db.collection("Users").document(blockedUserID)

            batch.updateData([
                "blockList": FieldValue.arrayRemove([blockedUserID])
            ], forDocument: userRef)

            batch.updateData([
                "wasBlockedByList": FieldValue.arrayRemove([userID])
            ], forDocument: blockedUserRef)

            batch.commit { error in
                if let error = error {
                    print("移除封鎖失敗：\(error.localizedDescription)")
                    completion(false)
                } else {
                    print("成功移除雙向封鎖")
                    completion(true)
                }
            }
        }
}
