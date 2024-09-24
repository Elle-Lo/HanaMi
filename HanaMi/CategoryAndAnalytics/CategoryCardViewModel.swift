import SwiftUI
import Combine

class CategoryCardViewModel: ObservableObject {
    @Published var showTreasureDeleteAlert = false
    @Published var isPublic: Bool
    @Published var selectedCategory: String
    @Published var categories: [String] = []

    let treasure: Treasure
    let userID: String
    var firestoreService = FirestoreService()

    init(treasure: Treasure, userID: String) {
        self.treasure = treasure
        self.userID = userID
        self.isPublic = treasure.isPublic
        self.selectedCategory = treasure.category
    }

    func loadCategories() {
        firestoreService.loadCategories(userID: userID, defaultCategories: []) { fetchedCategories in
            DispatchQueue.main.async {
                self.categories = fetchedCategories
            }
        }
    }

    func updateTreasureFields() {
        guard let treasureID = treasure.id else { return }
        firestoreService.updateTreasureFields(
            userID: userID,
            treasureID: treasureID,
            category: selectedCategory,
            isPublic: isPublic
        ) { success in
            // 根据需要处理成功或错误
        }
    }

    func deleteTreasure(completion: @escaping (Bool) -> Void) {
        guard let treasureID = treasure.id else {
            print("Error: Treasure ID is nil. Cannot delete.")
            completion(false)
            return
        }

        firestoreService.deleteSingleTreasure(userID: userID, treasureID: treasureID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Treasure successfully deleted")
                    completion(true)
                case .failure(let error):
                    print("Error deleting treasure: \(error)")
                    completion(false)
                }
            }
        }
    }
}
