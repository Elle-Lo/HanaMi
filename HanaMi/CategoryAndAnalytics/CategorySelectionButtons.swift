import SwiftUI

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
                    .padding(.vertical, 11)
                    .padding(.horizontal, 18)
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .background(selectedCategory == "All" ? Color.colorYellow : Color.white.opacity(0.55))
                    .foregroundColor(selectedCategory == "All" ? Color.colorBrown : Color.gray)
                    .cornerRadius(25)
            }

            ForEach(categories, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                    onSelectCategory(category)
                }) {
                    Text(category)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 18)
                        .font(.custom("LexendDeca-SemiBold", size: 15))
                        .background(selectedCategory == category ? Color.colorYellow : Color.white.opacity(0.55))
                        .foregroundColor(selectedCategory == category ? Color.colorBrown : Color.gray)
                        .cornerRadius(25)
                }
            }

            Button(action: {
                onAddCategory()
            }) {
                Label("Add Category", systemImage: "plus")
                    .padding(.vertical, 11)
                    .padding(.horizontal, 18)
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .background(Color.white.opacity(0.55))
                    .foregroundColor(.black)
                    .cornerRadius(25)
            }
        }
        .padding(.horizontal)
    }
}
