import SwiftUI
import FirebaseFirestore

struct CategorySelectionView: View {
    @Binding var selectedCategory: String
    @Binding var categories: [String]
    @State private var showAddCategorySheet: Bool = false
    @State private var newCategory: String = ""
    let db = Firestore.firestore()
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
            loadCategoriesFromFirestore()
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
                            saveCategoryToFirestore(category: newCategory) { success in
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

    // 加載 Firestore 的類別數據
    private func loadCategoriesFromFirestore() {
        let userDocument = db.collection("Users").document(userID)

        userDocument.addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error fetching Firestore document: \(error)")
            } else if let document = documentSnapshot, document.exists {
                if let categoryArray = document.data()?["category"] as? [String] {
                    self.categories = categoryArray
                    if !self.categories.isEmpty {
                        self.selectedCategory = self.categories.first ?? "Creative"
                    }
                } else {
                    // 如果文檔存在但沒有 category，設置預設類別
                    self.setDefaultCategoriesToFirestore()
                }
            } else {
                // 如果文檔不存在，設置預設類別
                self.setDefaultCategoriesToFirestore()
            }
        }
    }

    // 設置 Firestore 的預設類別
    private func setDefaultCategoriesToFirestore() {
        let userDocument = db.collection("Users").document(userID)

        userDocument.setData([
            "category": defaultCategories
        ]) { error in
            if let error = error {
                print("Error setting default categories: \(error)")
            } else {
                self.categories = defaultCategories
                self.selectedCategory = defaultCategories.first ?? "Creative"
                print("Default categories set in Firestore")
            }
        }
    }

    // 保存新類別到 Firestore
    private func saveCategoryToFirestore(category: String, completion: @escaping (Bool) -> Void) {
        let userDocument = db.collection("Users").document(userID)

        userDocument.updateData([
            "category": FieldValue.arrayUnion([category])
        ]) { error in
            if let error = error {
                print("Error updating Firestore: \(error)")
                completion(false)
            } else {
                print("Category updated successfully in Firestore")
                completion(true)
            }
        }
    }
}


