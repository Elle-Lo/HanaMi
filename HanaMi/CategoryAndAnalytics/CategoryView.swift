import SwiftUI

struct CategoryView: View {
    @State private var categories: [String] = []
    @State private var selectedCategory: String?
    @State private var treasures: [Treasure] = []
    @State private var isAddingCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryValidationMessage: String?
    @State private var showEditOptions = false
    @State private var showCategoryDeleteAlert = false
    @State private var showChangeNameAlert = false
    @State private var editedCategoryName = ""
    @State private var editCategoryValidationMessage: String?
    @State private var isLoading = true
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    var body: some View {
        ZStack {
            
            Color(.colorGrayBlue)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading) {
                Text("Category")
                    .foregroundColor(.colorBrown)
                    .font(.custom("LexendDeca-Bold", size: 30))
                    .padding(.leading, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    CategorySelectionButtons(
                        categories: $categories,
                        selectedCategory: $selectedCategory,
                        onSelectCategory: { category in
                            if category == "All" {
                                loadAllTreasures()
                            } else {
                                loadTreasuresDetail(for: category)
                            }
                        },
                        onAddCategory: {
                            isAddingCategory = true
                        }
                    )
                }
                .background(Color.clear)
                .padding(.bottom, 10)
                
                    .sheet(isPresented: $isAddingCategory) {
                        AddCategoryForm(
                            newCategoryName: $newCategoryName,
                            newCategoryValidationMessage: $newCategoryValidationMessage,
                            categories: $categories,
                            userID: userID,
                            onAddSuccess: {
                                loadCategories()
                                isAddingCategory = false
                                newCategoryName = ""
                                newCategoryValidationMessage = nil
                            }
                        )
                        .presentationDetents([.fraction(0.2)])
                        .presentationDragIndicator(.hidden)
                    }
                
                TreasureListView(
                    treasures: $treasures,
                    categories: $categories,
                    selectedCategory: $selectedCategory,
                    isLoading: isLoading,
                    loadAllTreasures: loadAllTreasures,
                    loadTreasuresDetail: loadTreasuresDetail,
                    onDeleteTreasure: { treasure in
                        treasures.removeAll { $0.id == treasure.id }
                    }
                )
                .frame(maxWidth: .infinity)
                .background(Color.clear)
            }
            .onAppear {
                selectedCategory = "All"
                loadAllTreasures()
                loadCategories()
            }
     
            if selectedCategory != "All" && selectedCategory != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showEditOptions = true
                        }) {
                            ZStack {
                                
                                Circle()
                                    .fill(Color(hex: "522504"))
                                    .frame(width: 55, height: 55)

                                Image(systemName: "pencil")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(Color(hex: "FFF7EF"))
                            }
                        }
                        .padding()
                        .offset(x: -10, y: -10)
                    }
                }
            }

        }
        
        .confirmationDialog("編輯類別", isPresented: $showEditOptions, titleVisibility: .visible) {
            Button("刪除類別", role: .destructive) {
                showCategoryDeleteAlert = true
            }
            Button("更改名稱") {
                showChangeNameAlert = true
            }
            Button("取消", role: .cancel) { }
        }
        
        .alert("刪除類別", isPresented: $showCategoryDeleteAlert) {
            Button("確認", role: .destructive) {
                if let category = selectedCategory {
                    deleteCategory(category)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("您確認要删除該類別及其所有寶藏嗎？")
        }
        
        .alert("更改類別名稱", isPresented: $showChangeNameAlert) {
            TextField("新類別名稱", text: $editedCategoryName)
                .onChange(of: editedCategoryName) { _ in
                    validateEditedCategoryName()
                }
            Button("送出") {
                let trimmedName = editedCategoryName.trimmingCharacters(in: .whitespaces)
                if let category = selectedCategory {
                    FirestoreService().updateCategoryNameAndTreasures(userID: userID, oldName: category, newName: trimmedName) { success in
                        if success {
                          
                            if let index = categories.firstIndex(of: category) {
                                categories[index] = trimmedName
                            }
                            selectedCategory = trimmedName
                            
                            categories = categories.map { $0 }
                           
                            loadTreasuresDetail(for: trimmedName)
                            
                            DispatchQueue.main.async {
                                editedCategoryName = ""
                                editCategoryValidationMessage = nil
                            }
                        } else {
                            print("類別名稱或寶藏更新失敗")
                        }
                    }
                }
            }
            .disabled(editCategoryValidationMessage != nil)
            Button("取消", role: .cancel) {
                editedCategoryName = ""
                editCategoryValidationMessage = nil
            }
        } message: {
            if let message = editCategoryValidationMessage {
                Text(message)
            } else {
                Text("請輸入新的類別名稱")
            }
        }
    }
    
    private func validateNewCategoryName() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            newCategoryValidationMessage = "類別名稱不能為空或全為空格"
        } else if categories.contains(trimmedName) {
            newCategoryValidationMessage = "類別已存在"
        } else {
            newCategoryValidationMessage = nil
        }
    }
    
    private func validateEditedCategoryName() {
        let trimmedName = editedCategoryName.trimmingCharacters(in: .whitespaces)
        
        if trimmedName.isEmpty {
            editCategoryValidationMessage = "類別名稱不能為空或全為空格"
        } else if trimmedName == selectedCategory {
            editCategoryValidationMessage = "新名稱不能與當前類別名稱相同"
        } else if categories.contains(trimmedName) {
            editCategoryValidationMessage = "類別已存在"
        } else {
            editCategoryValidationMessage = nil
        }
    }
    
    private func loadCategories() {
        FirestoreService().loadCategories(userID: userID) { fetchedCategories in
            DispatchQueue.main.async {
                self.categories = fetchedCategories
            }
        }
    }

    private func loadTreasuresDetail(for category: String) {
        FirestoreService().fetchTreasuresForCategory(userID: userID, category: category) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let treasures):
                    self.treasures = treasures
                case .failure(let error):
                    print("Error fetching treasures: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadAllTreasures() {
        FirestoreService().fetchAllTreasures(userID: userID) { result in
            DispatchQueue.main.async {
                isLoading = false 
                switch result {
                case .success(let treasures):
                    self.treasures = treasures
                case .failure(let error):
                    print("Error fetching all treasures: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteCategory(_ category: String) {
        FirestoreService().deleteCategoryAndTreasures(userID: userID, category: category) { success in
            if success {
                loadCategories()
                selectedCategory = "All"
                loadAllTreasures()
            }
        }
    }
    
}
