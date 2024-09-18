import Foundation
//import Combine
import MapKit

class TreasureManager: ObservableObject {
//    @Published var treasures: [Treasure] = [] // 所有寶藏數據（只包含基礎信息）
    @Published var displayedTreasures: [TreasureSummary] = [] // 地圖範圍內要顯示的寶藏
    let userID = "g61HUemIJIRIC1wvvIqa"
    // 加載寶藏基本數據（例如從 Firestore 獲取，僅包含位置等信息）
    func fetchTreasuresNear(coordinate: CLLocationCoordinate2D, radius: Double) {
        FirestoreService().fetchPublicTreasuresNear(coordinate: coordinate, radius: radius) { [weak self] result in
            switch result {
            case .success(let treasures):
                DispatchQueue.main.async {
                    self?.displayedTreasures = treasures
                }
            case .failure(let error):
                print("Error fetching treasures: \(error.localizedDescription)")
            }
        }
    }

    // 根據寶藏 ID 查詢具體的寶藏詳細資料
    func fetchTreasureDetails(treasureID: String, completion: @escaping (Result<Treasure, Error>) -> Void) {
        FirestoreService().fetchTreasure(userID: userID, treasureID: treasureID) { result in
            completion(result)
        }
    }
}
