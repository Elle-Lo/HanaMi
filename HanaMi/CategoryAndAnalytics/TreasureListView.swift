import SwiftUI

struct TreasureListView: View {
    @Binding var treasures: [Treasure]
    @Binding var categories: [String]
    @Binding var selectedCategory: String? // 添加 Binding
    var isLoading: Bool // 加載狀態
    var loadAllTreasures: () -> Void
    var loadTreasuresDetail: (String) -> Void
    var onDeleteTreasure: (Treasure) -> Void
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    var body: some View {
        ScrollView {
            if isLoading {
                // 顯示加載中的進度視圖
                VStack {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .colorBrown)) // 加載進度的樣式
                        .padding()
                }
            } else if treasures.isEmpty {
                // 當寶藏數據為空時顯示的視圖
                Text("No treasures found")
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .foregroundColor(.colorBrown)
                    .padding()
            } else {
                // 顯示寶藏數據
                ForEach(treasures) { treasure in
                    CategoryCardView(
                        treasure: treasure,
                        userID: userID,
                        selectedCategory: $selectedCategory, // 傳遞 Binding<String?>
                        categories: $categories,
                        onDelete: {
                            onDeleteTreasure(treasure)
                        },
                        onCategoryChange: { newCategory in
                            // 使用回調處理 categories 的更新
                            if !categories.contains(newCategory) {
                                categories.append(newCategory)
                            }
                            
                            // 根據 selectedCategory 加載寶藏
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
