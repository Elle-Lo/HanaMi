import SwiftUI
import FirebaseFirestore

struct CategorySelectionView: View {
    @Binding var selectedCategory: String
    @Binding var categories: [String]
    @State private var showAddCategorySheet: Bool = false
    @State private var newCategory: String = ""
    let firestoreService = FirestoreService()
    let userID: String
    let defaultCategories = ["Creative", "Energetic", "Happy"]

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                    }
                }

                Button(action: {
                    showAddCategorySheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("新增類別")
                    }
                }
            } label: {
                Text(selectedCategory)
                    .font(.system(size: 13))
                    .fontWeight(.bold)
                    .padding(.vertical, 13)
                    .padding(.horizontal, 20)
                    .foregroundColor(Color(hex: "#FFF7EF"))
                    .background(Color(hex: "#CDCDCD"))
                    .cornerRadius(25)
            }
        }
        .padding(.horizontal)
        .onAppear {
            firestoreService.loadCategories(userID: userID, defaultCategories: defaultCategories) { loadedCategories in
                categories = loadedCategories
                // 不再修改 selectedCategory，以避免覆盖父视图的值
            }
        }
        .sheet(isPresented: $showAddCategorySheet) {
            VStack {
                Text("新增類別")
                    .font(.headline)
                    .padding(.top)

                TextField("請輸入新的類別名稱", text: $newCategory)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                HStack {
                    Button("取消") {
                        showAddCategorySheet = false
                        newCategory = ""
                    }
                    .foregroundColor(.red)

                    Spacer()

                    Button("完成") {
                        if !newCategory.isEmpty {
                            firestoreService.addCategory(userID: userID, category: newCategory) { success in
                                if success {
                                    selectedCategory = newCategory
                                    categories.append(newCategory)
                                    showAddCategorySheet = false
                                    newCategory = ""
                                }
                            }
                        }
                    }
                    .foregroundColor(.blue)
                }
                .padding()

                Spacer()
            }
            .frame(height: 200)
            .presentationDetents([.fraction(0.25)])
        }
    }
}
