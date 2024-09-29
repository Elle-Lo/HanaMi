import SwiftUI

struct CategoryView: View {
    @State private var categories: [String] = []
    @State private var selectedCategory: String?
    @State private var treasures: [Treasure] = []
    @State private var isAddingCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryValidationMessage: String? = nil
    @State private var showEditOptions = false
    @State private var showCategoryDeleteAlert = false
    @State private var showChangeNameAlert = false
    @State private var editedCategoryName = ""
    @State private var editCategoryValidationMessage: String? = nil
    private var userID: String = "g61HUemIJIRIC1wvvIqa"

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                // 类别标题
                Text("Category")
                    .font(.largeTitle)
                    .bold()
                    .padding([.top, .leading])

                // 类别 Collection View
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        // "All" 按钮
                        Button(action: {
                            selectedCategory = "All"
                            loadAllTreasures()
                        }) {
                            Text("All")
                                .padding(.vertical, 13)
                                .padding(.horizontal, 18)
                                .background(selectedCategory == "All" ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == "All" ? Color.white : Color.black)
                                .cornerRadius(25)
                        }

                        // 动态加载类别按钮
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                loadTreasuresDetail(for: category)
                            }) {
                                Text(category)
                                    .padding(.vertical, 13)
                                    .padding(.horizontal, 18)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == category ? Color.white : Color.black)
                                    .cornerRadius(25)
                            }
                        }

                        // 添加新类别按钮
                        Button(action: {
                            isAddingCategory = true
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
                Spacer().frame(height: 20)

                // 显示添加类别的对话框
                .sheet(isPresented: $isAddingCategory) {
                    VStack(spacing: 15) {
                        Text("新增類別")
                            .font(.headline)
                            .padding(.top, 10)

                        TextField("輸入新類別名稱", text: $newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                            .padding(.horizontal, 20)
                            .onChange(of: newCategoryName) { _ in
                                validateNewCategoryName()
                            }

                        if let message = newCategoryValidationMessage {
                            Text(message)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        Button("添加類別") {
                            let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
                            FirestoreService().addCategory(userID: userID, category: trimmedName) { success in
                                if success {
                                    loadCategories()
                                    isAddingCategory = false
                                    newCategoryName = ""
                                    newCategoryValidationMessage = nil
                                }
                            }
                        }
                        .frame(width: 100)
                        .disabled(newCategoryValidationMessage != nil)
                    }
                    .padding()
                    .frame(width: 300, height: 300)
                }

                // 类别下的宝藏列表
                ScrollView {
                    if treasures.isEmpty {
                        Text("No treasures found")
                            .padding()
                    } else {
                        ForEach(treasures) { treasure in
                            CategoryCardView(
                                treasure: treasure,
                                userID: userID,
                                onDelete: {
                                    treasures.removeAll { $0.id == treasure.id }
                                },
                                onCategoryChange: { newCategory in
                                    if !categories.contains(newCategory) {
                                        categories.append(newCategory)
                                    }
                                    // 重新加载宝藏列表
                                    if let selectedCategory = selectedCategory {
                                        if selectedCategory == "All" {
                                            loadAllTreasures()
                                        } else {
                                            loadTreasuresDetail(for: selectedCategory)
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
                .frame(maxWidth: .infinity)
                .background(Color.clear)
            }
            .onAppear {
                selectedCategory = "All"
                loadAllTreasures()
                loadCategories()
            }

            // 在右下角添加编辑按钮
            if selectedCategory != "All" && selectedCategory != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showEditOptions = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.blue)
                                .padding()
                        }
                    }
                }
            }
        }

        // 弹出操作选项
        .confirmationDialog("編輯類別", isPresented: $showEditOptions, titleVisibility: .visible) {
            Button("刪除類別", role: .destructive) {
                showCategoryDeleteAlert = true
            }
            Button("更改名稱") {
                showChangeNameAlert = true
            }
            Button("取消", role: .cancel) { }
        }

        // 删除类别确认框
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

        // 更改名称弹窗
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
                            print("類別名稱和寶藏更新成功")
                            loadCategories()
                            selectedCategory = trimmedName
                            editedCategoryName = ""
                            editCategoryValidationMessage = nil
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

    // 验证新类别名称
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

    // 验证编辑的类别名称
    private func validateEditedCategoryName() {
        let trimmedName = editedCategoryName.trimmingCharacters(in: .whitespaces)
        
        // 名称不能为空
        if trimmedName.isEmpty {
            editCategoryValidationMessage = "類別名稱不能為空或全為空格"
        
        // 检查用户输入的新名称是否与当前选中的类别相同
        } else if trimmedName == selectedCategory {
            editCategoryValidationMessage = "新名稱不能與當前類別名稱相同"
        
        // 检查新名称是否已经存在
        } else if categories.contains(trimmedName) {
            editCategoryValidationMessage = "類別已存在"
        
        // 否则通过验证
        } else {
            editCategoryValidationMessage = nil
        }
    }


    // 加载所有类别
    private func loadCategories() {
        
        FirestoreService().loadCategories(userID: userID, defaultCategories: []) { fetchedCategories in
            DispatchQueue.main.async {
                self.categories = fetchedCategories
            }
        }
    }

    // 加载特定类别的宝藏
    private func loadTreasuresDetail(for category: String) {
        FirestoreService().fetchTreasuresForCategory(userID: userID, category: category) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let treasures):
                    self.treasures = treasures
                case .failure(let error):
                    print("Error fetching treasures: \(error.localizedDescription)")
                }
            }
        }
    }

    // 加载所有宝藏
    private func loadAllTreasures() {
        FirestoreService().fetchAllTreasures(userID: userID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let treasures):
                    self.treasures = treasures
                case .failure(let error):
                    print("Error fetching all treasures: \(error.localizedDescription)")
                }
            }
        }
    }

    // 删除选中的类别及其宝藏
    private func deleteCategory(_ category: String) {
        FirestoreService().deleteCategory(userID: userID, category: category) { success in
            if success {
                loadCategories()
                selectedCategory = "All"
                loadAllTreasures()
            }
        }
    }
}
