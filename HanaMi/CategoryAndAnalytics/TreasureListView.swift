import SwiftUI

struct TreasureListView: View {
    @Binding var treasures: [Treasure]
    @Binding var categories: [String]
    @Binding var selectedCategory: String?
    var isLoading: Bool
    var loadAllTreasures: () -> Void
    var loadTreasuresDetail: (String) -> Void
    var onDeleteTreasure: (Treasure) -> Void
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    var body: some View {
        ScrollView {
            if isLoading {
               
                VStack {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .colorBrown))
                        .padding()
                }
            } else if treasures.isEmpty {
               
                Text("No treasures found")
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .foregroundColor(.colorBrown)
                    .padding()
            } else {
             
                ForEach(treasures) { treasure in
                    CategoryCardView(
                        treasure: treasure,
                        userID: userID,
                        selectedCategory: $selectedCategory,
                        categories: $categories,
                        onDelete: {
                            onDeleteTreasure(treasure)
                        },
                        onCategoryChange: { newCategory in
                           
                            if !categories.contains(newCategory) {
                                categories.append(newCategory)
                            }
                            
                            if let selectedCategory = selectedCategory {
                                if selectedCategory == "All" {
                                    loadAllTreasures()
                                } else {
                                    loadTreasuresDetail(selectedCategory)
                                }
                            } else {
                                loadAllTreasures()
                            }
                        }
                    )
                    .id(treasure.id)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                }
            }
        }
    }
}
