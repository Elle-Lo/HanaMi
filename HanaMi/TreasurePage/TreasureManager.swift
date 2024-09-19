import Foundation
import MapKit

class TreasureManager: ObservableObject {
    @Published var treasures: [Treasure] = [] // 缓存的宝藏列表
    @Published var displayedTreasures: [TreasureSummary] = [] // 地圖範圍內要顯示的寶藏
    let firestoreService = FirestoreService()
    
    private let userID = "g61HUemIJIRIC1wvvIqa" // 使用當前用戶的ID
    
    // 加載所有公開的寶藏
    func fetchAllPublicTreasures(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping ([TreasureSummary]) -> Void) {
        FirestoreService().fetchAllTreasuresNear(userID: userID, minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { [weak self] result in
            switch result {
            case .success(let treasures):
                DispatchQueue.main.async {
                    self?.displayedTreasures = treasures
                    completion(treasures)
                }
            case .failure(let error):
                print("Error fetching public treasures: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    // 加载用户自己的宝藏（包括公开和非公开）
    func fetchUserTreasures(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping ([TreasureSummary]) -> Void) {
        FirestoreService().fetchUserTreasuresNear(userID: userID, minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { [weak self] result in
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
    
    // 从缓存或远程获取宝藏详细信息
    func getTreasure(by treasureID: String, for userID: String, completion: @escaping (Treasure?) -> Void) {
        // 首先检查缓存
        if let cachedTreasure = treasures.first(where: { $0.id == treasureID }) {
            completion(cachedTreasure)
            return
        }
        
        // 如果缓存中没有，调用 FirestoreService 获取数据
        firestoreService.fetchTreasure(userID: userID, treasureID: treasureID) { result in
            switch result {
            case .success(let treasure):
                DispatchQueue.main.async {
                    // 将获取到的宝藏添加到缓存中
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
