import Foundation
import MapKit

class TreasureManager: ObservableObject {
    @Published var treasures: [Treasure] = [] // 缓存的宝藏列表
    @Published var displayedTreasures: [TreasureSummary] = [] // 地圖範圍內要顯示的寶藏
    let firestoreService = FirestoreService()
    
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    // 加載所有公開的寶藏以及當前用戶的所有寶藏
    func fetchAllPublicAndUserTreasures(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping ([TreasureSummary]) -> Void) {
        let userID = self.userID // 直接使用userID，因為它不是可選的
        
        // 創建 DispatchGroup 來管理兩個請求的並行處理
        let dispatchGroup = DispatchGroup()
        
        var publicTreasures: [TreasureSummary] = []
        var userTreasures: [TreasureSummary] = []
        
        // 先抓取所有公開寶藏
        // 先抓取所有公開寶藏
        dispatchGroup.enter()
        firestoreService.fetchAllTreasuresNear(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { result in
            switch result {
            case .success(let fetchedPublicTreasures):
                publicTreasures = fetchedPublicTreasures
            case .failure(let error):
                print("Error fetching public treasures: \(error.localizedDescription)")
            }
            dispatchGroup.leave()
        }

        
        // 再抓取當前用戶的所有寶藏
        dispatchGroup.enter()
        firestoreService.fetchUserTreasuresNear(userID: userID, minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { result in
            switch result {
            case .success(let fetchedUserTreasures):
                userTreasures = fetchedUserTreasures
            case .failure(let error):
                print("Error fetching user's treasures: \(error.localizedDescription)")
            }
            dispatchGroup.leave()
        }
        
        // 當兩個請求都完成後，合併結果
        dispatchGroup.notify(queue: .main) {
            let allTreasures = publicTreasures + userTreasures
            self.displayedTreasures = allTreasures
            completion(allTreasures)
        }
    }

    
    // 只抓取當前用戶自己的寶藏（公開和非公開）
    func fetchUserTreasures(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping ([TreasureSummary]) -> Void) {
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
    func getTreasure(by treasureID: String, for userID: String, completion: @escaping (Treasure?) -> Void) {
        // 先檢查緩存
        if let cachedTreasure = treasures.first(where: { $0.id == treasureID }) {
            completion(cachedTreasure)
            return
        }
        
        // 如果緩存中沒有，調用 FirestoreService 獲取數據
        firestoreService.fetchTreasure(userID: userID, treasureID: treasureID) { result in
            switch result {
            case .success(let treasure):
                DispatchQueue.main.async {
                    // 將獲取到的寶藏添加到緩存中
                    self.treasures.append(treasure)
                    completion(treasure)
                }
            case .failure(let error):
                print("Failed to fetch treasure: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}
