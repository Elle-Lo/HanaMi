import SwiftUI

struct TreasureListView: View {
    @Binding var treasures: [Treasure]
    @Binding var categories: [String]
    @Binding var selectedCategory: String? // 添加 Binding
    var loadAllTreasures: () -> Void
    var loadTreasuresDetail: (String) -> Void
    var onDeleteTreasure: (Treasure) -> Void
    private var userID: String {
           return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
       }
    
    var body: some View {
        ScrollView {
            if treasures.isEmpty {
                Text("No treasures found")
                    .font(.custom("LexendDeca-SemiBold", size: 12))
                    .foregroundColor(.colorBrown)
                    .padding()
            } else {
                ForEach(treasures) { treasure in
                    CategoryCardView(
                        treasure: treasure,
                        userID: userID,
                        selectedCategory: $selectedCategory, // 传递 Binding<String?>
                        categories: $categories,
                        onDelete: {
                            onDeleteTreasure(treasure)
                        },
                        onCategoryChange: { newCategory in
                            // 使用回调处理 categories 的更新
                            if !categories.contains(newCategory) {
                                categories.append(newCategory)
                            }
                            
                            // 根据 selectedCategory 加载宝藏
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
