import SwiftUI
import FirebaseFirestore

struct CategorySelectionView: View {
    @Binding var selectedCategory: String
    @Binding var categories: [String]
    @State private var showAddCategorySheet: Bool = false
    @State private var newCategory: String = ""
    @State private var validationMessage: String? = nil
    let firestoreService = FirestoreService()
    let userID: String
    
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
            firestoreService.loadCategories(userID: userID) { loadedCategories in
                categories = loadedCategories
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
                    .onChange(of: newCategory) { _ in
                        validateCategory()
                    }
                
                if let message = validationMessage {
                    Text(message)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                HStack {
                    Button("取消") {
                        showAddCategorySheet = false
                        newCategory = ""
                        validationMessage = nil
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("完成") {
                        let trimmedCategory = newCategory.trimmingCharacters(in: .whitespaces)
                        firestoreService.addCategory(userID: userID, category: trimmedCategory) { success in
                            if success {
                                selectedCategory = trimmedCategory
                                categories.append(trimmedCategory)
                                showAddCategorySheet = false
                                newCategory = ""
                                validationMessage = nil
                            }
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(validationMessage != nil)
                }
                .padding()
                
                Spacer()
            }
            .frame(height: 200)
            .presentationDetents([.fraction(0.25)])
        }
    }
    
    private func validateCategory() {
        let trimmedCategory = newCategory.trimmingCharacters(in: .whitespaces)
        if trimmedCategory.isEmpty {
            validationMessage = "類別名稱不能為空或全為空格"
        } else if categories.contains(trimmedCategory) {
            validationMessage = "類別已存在"
        } else {
            validationMessage = nil
        }
    }
}
