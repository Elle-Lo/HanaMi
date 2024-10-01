import SwiftUI

// 拆分类别选择视图为子视图
struct CategorySelectionButtons: View {
    @Binding var categories: [String]
    @Binding var selectedCategory: String?
    var onSelectCategory: (String) -> Void
    var onAddCategory: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                selectedCategory = "All"
                onSelectCategory("All")
            }) {
                Text("All")
                    .padding(.vertical, 13)
                    .padding(.horizontal, 18)
                    .background(selectedCategory == "All" ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedCategory == "All" ? Color.white : Color.black)
                    .cornerRadius(25)
            }

            ForEach(categories, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                    onSelectCategory(category)
                }) {
                    Text(category)
                        .padding(.vertical, 13)
                        .padding(.horizontal, 18)
                        .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == category ? Color.white : Color.black)
                        .cornerRadius(25)
                }
            }

            Button(action: {
                onAddCategory()
            }) {
                Label("Add Category", systemImage: "plus")
                    .padding(.vertical, 13)
                    .padding(.horizontal, 18)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(25)
            }
        }
        .padding(.horizontal)
    }
}
