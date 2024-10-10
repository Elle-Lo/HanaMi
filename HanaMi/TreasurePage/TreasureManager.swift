import Foundation
import MapKit

class TreasureManager: ObservableObject {
    @Published var treasures: [Treasure] = [] // 缓存的宝藏列表
    @Published var displayedTreasures: [TreasureSummary] = [] // 地圖範圍內要顯示的寶藏
    let firestoreService = FirestoreService()
    
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    func clearDisplayedTreasures() {
            displayedTreasures.removeAll()
        }
    
    // 加載所有公開的寶藏以及當前用戶的所有寶藏
    func fetchAllPublicAndUserTreasures(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping ([TreasureSummary]) -> Void) {
        self.displayedTreasures.removeAll() // 清空舊的寶藏
        
            DispatchQueue.main.async {
                self.displayedTreasures.removeAll() // 確保清空舊的寶藏在主線程上執行
            }

            let dispatchGroup = DispatchGroup()
            var publicTreasures: [TreasureSummary] = []

            // 先抓取所有公開寶藏
            dispatchGroup.enter()
            firestoreService.fetchAllTreasuresNear(minLat: minLat, maxLat: maxLat, maxLng: maxLng, minLng: minLng, currentUserID: userID) { result in
                switch result {
                case .success(let fetchedPublicTreasures):
                    publicTreasures = fetchedPublicTreasures
                case .failure(let error):
                    print("Error fetching public treasures: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }

            dispatchGroup.notify(queue: .main) {
                // 確保所有結果合併並回傳後在主線程上更新 displayedTreasures
                self.displayedTreasures = publicTreasures
                completion(publicTreasures)
            }
        }

    
    // 只抓取當前用戶自己的寶藏（公開和非公開）
    func fetchUserTreasures(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping ([TreasureSummary]) -> Void) {
        self.displayedTreasures.removeAll() // 清空舊的寶藏
        
        firestoreService.fetchUserTreasuresNear(userID: userID, minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { [weak self] result in
            switch result {
            case .success(let treasures):
                DispatchQueue.main.async {
                    self?.displayedTreasures = treasures
                    completion(treasures)
                }
            case .failure(let error):
                print("Error fetching user's treasures: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    // 從緩存或遠程獲取寶藏詳細信息
//    func getTreasure(by treasureID: String, for userID: String, completion: @escaping (Treasure?) -> Void) {
//        // 先檢查緩存
//        if let cachedTreasure = treasures.first(where: { $0.id == treasureID }) {
//            completion(cachedTreasure)
//            return
//        }
//        
//        // 判斷是否是當前用戶的寶藏
//        if userID == self.userID {  // 如果是當前用戶，使用用戶路徑查詢
//            print(userID)
//            firestoreService.fetchTreasure(userID: userID, treasureID: treasureID) { result in
//                switch result {
//                case .success(let treasure):
//                    DispatchQueue.main.async {
//                        // 將獲取到的寶藏添加到緩存中
//                        self.treasures.append(treasure)
//                        completion(treasure)
//                    }
//                case .failure(let error):
//                    print("Failed to fetch treasure: \(error.localizedDescription)")
//                    completion(nil)
//                }
//            }
//        } else {  // 如果是其他用戶的寶藏，從 "AllTreasures" 集合中查詢
//            print(userID)
//            firestoreService.fetchTreasureFromAllTreasures(treasureID: treasureID) { result in
//                switch result {
//                case .success(let treasure):
//                    DispatchQueue.main.async {
//                        // 將獲取到的寶藏添加到緩存中
//                        self.treasures.append(treasure)
//                        completion(treasure)
//                    }
//                case .failure(let error):
//                    print("Failed to fetch treasure from AllTreasures: \(error.localizedDescription)")
//                    completion(nil)
//                }
//            }
//        }
//    }
    func getTreasure(by treasureID: String, completion: @escaping (Treasure?) -> Void) {
        // 先檢查緩存
        if let cachedTreasure = treasures.first(where: { $0.id == treasureID }) {
            completion(cachedTreasure)
            return
        }

        // 直接從 "AllTreasures" 集合中查詢
        print("Fetching treasure from AllTreasures with ID: \(treasureID)")
        firestoreService.fetchTreasureFromAllTreasures(treasureID: treasureID) { result in
            switch result {
            case .success(let treasure):
                DispatchQueue.main.async {
                    // 將獲取到的寶藏添加到緩存中
                    self.treasures.append(treasure)
                    completion(treasure)
                }
            case .failure(let error):
                print("Failed to fetch treasure from AllTreasures: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

}
