import Foundation
import MapKit

class TreasureManager: ObservableObject {
    @Published var treasures: [Treasure] = []
    @Published var displayedTreasures: [TreasureSummary] = []
    
    let firestoreService = FirestoreService()
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
//    func clearDisplayedTreasures() {
//            displayedTreasures.removeAll()
//        }
    
    func fetchAllPublicAndUserTreasures(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping ([TreasureSummary]) -> Void) {
    
        DispatchQueue.main.async {
            self.displayedTreasures.removeAll()
        }

        let dispatchGroup = DispatchGroup()
        var publicTreasures: [TreasureSummary] = []

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
            DispatchQueue.main.async {
                self.displayedTreasures = publicTreasures
                completion(publicTreasures)
            }
        }
    }

    func fetchUserTreasures(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double, completion: @escaping ([TreasureSummary]) -> Void) {
 
        DispatchQueue.main.async {
            self.displayedTreasures.removeAll()
        }

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

    func getTreasure(by treasureID: String, completion: @escaping (Treasure?) -> Void) {
        
        if let cachedTreasure = treasures.first(where: { $0.id == treasureID }) {
            completion(cachedTreasure)
            return
        }

        print("Fetching treasure from AllTreasures with ID: \(treasureID)")
        firestoreService.fetchTreasureFromAllTreasures(treasureID: treasureID) { result in
            switch result {
            case .success(let treasure):
                DispatchQueue.main.async {
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
