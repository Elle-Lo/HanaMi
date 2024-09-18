import SwiftUI
import FirebaseFirestore

struct CategorySelectionView: View {
    @Binding var selectedCategory: String
    @Binding var categories: [String]
    @State private var showAddCategorySheet: Bool = false
    @State private var newCategory: String = ""
    let firestoreService = FirestoreService() // 使用 FirestoreService 管理 Firebase 交互
    let userID: String
    let defaultCategories = ["Creative", "Energetic", "Happy"] // 預設的三個類別

    var body: some View {
        HStack(spacing: 20) {
            // 類別選擇按鈕
            Menu {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                    }
                }

                // 顯示新增類別的選項
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
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .padding()
                    .frame(width: 120)
                    .foregroundColor(.black)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .onAppear {
            firestoreService.loadCategories(userID: userID, defaultCategories: defaultCategories) { loadedCategories in
                categories = loadedCategories
                if !loadedCategories.isEmpty {
                    selectedCategory = loadedCategories.first ?? "Creative"
                }
            }
        }
        .sheet(isPresented: $showAddCategorySheet) {
            // Sheet 內容
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
                        newCategory = "" // 清空輸入框
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
                                    newCategory = "" // 清空輸入框
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
