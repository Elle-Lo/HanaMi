import SwiftUI

struct CategoryView: View {
    @State private var categories: [String] = []
    @State private var selectedCategory: String?
    @State private var treasures: [Treasure] = []
    @State private var isAddingCategory = false  // 是否显示添加类别的弹窗
    @State private var newCategoryName = ""      // 存储新类别的名称
    @State private var showEditOptions = false   // 是否显示编辑选项
    @State private var showCategoryDeleteAlert = false  // 控制类别删除的 alert
    @State private var showChangeNameAlert = false  // 是否显示更改名称的弹窗
    @State private var editedCategoryName = ""   // 修改后的新类别名称
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
                        // "All" 按钮 - 放在第一个
                        Button(action: {
                            selectedCategory = "All"
                            loadAllTreasures()  // 加载所有宝藏
                        }) {
                            Text("All")
                                .padding(.vertical, 13)
                                .padding(.horizontal, 18)
                                .background(selectedCategory == "All" ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == "All" ? Color.white : Color.black)
                                .cornerRadius(25)
                        }

                        // 其余的动态加载类别按钮
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                loadTreasuresDetail(for: category)  // 加载该类别的宝藏
                            }) {
                                Text(category)
                                    .padding(.vertical, 13)
                                    .padding(.horizontal, 18)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == category ? Color.white : Color.black)
                                    .cornerRadius(25)
                            }
                        }

                        // 添加新类别按钮，带有加号图标
                        Button(action: {
                            isAddingCategory = true  // 显示添加类别的弹窗
                        }) {
                            Label("Add Category", systemImage: "plus")  // 使用系统图标
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
                    VStack(spacing: 15) {  // 控制垂直间距
                        Text("新增類別")
                            .font(.headline)
                            .padding(.top, 10)  // 控制标题和顶部的间距

                        TextField("输入新類別名稱", text: $newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)  // 控制 TextField 的宽度
                            .padding(.horizontal, 20)

                        Button("添加類別") {
                            FirestoreService().addCategory(userID: userID, category: newCategoryName) { success in
                                if success {
                                    loadCategories()  // 刷新类别列表
                                    isAddingCategory = false  // 关闭弹窗
                                }
                            }
                        }
                        .frame(width: 100)
                        .disabled(newCategoryName.isEmpty)
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
                                onCategoryChange: {
                                    // 宝藏类别更改后的回调，重新加载宝藏列表
                                    if let selectedCategory = selectedCategory {
                                        if selectedCategory == "All" {
                                            loadAllTreasures()
                                        } else {
                                            loadTreasuresDetail(for: selectedCategory)
                                        }
                                    } else {
                                        // 处理 selectedCategory 为 nil 的情况
                                        // 例如，可以加载所有宝藏，或者显示一个提示
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
                .frame(maxWidth: .infinity)  // ScrollView 占满可用宽度
                .ignoresSafeArea(edges: .horizontal)
                .background(Color.clear)
            }
            .onAppear {
                loadCategories() // 页面加载时加载类别
            }

            // 在右下角添加编辑按钮（若选中的不是 "All" 和 "Add Category" 时显示）
            if selectedCategory != "All" && selectedCategory != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showEditOptions = true  // 显示编辑选项
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
        .actionSheet(isPresented: $showEditOptions) {
            ActionSheet(
                title: Text("編輯類別"),
                buttons: [
                    .destructive(Text("刪除類別")) {
                        showCategoryDeleteAlert = true  // 显示删除确认框
                    },
                    .default(Text("更改名稱")) {
                        showChangeNameAlert = true  // 显示更改名称输入框
                    },
                    .cancel()
                ]
            )
        }

        // 删除类别确认框
        .alert(isPresented: $showCategoryDeleteAlert) {
            Alert(
                title: Text("删除類別"),
                message: Text("您確認要刪除该類別及其所有寶藏嗎？"),
                primaryButton: .destructive(Text("確認")) {
                    if let category = selectedCategory {
                        deleteCategory(category)  // 删除类别及所有宝藏
                    }
                },
                secondaryButton: .cancel()
            )
        }

        // 更改名称弹窗
        .alert("更改類別名稱", isPresented: $showChangeNameAlert) {
            TextField("新類別名稱", text: $editedCategoryName)
            Button("送出") {
                if !editedCategoryName.isEmpty, let category = selectedCategory {
                    FirestoreService().updateCategoryNameAndTreasures(userID: userID, oldName: category, newName: editedCategoryName) { success in
                        if success {
                            print("類别名稱和寶藏更新成功")
                            loadCategories()
                        } else {
                            print("類别名稱或寶藏更新失敗")
                        }
                    }
                }
            }

            Button("取消", role: .cancel) { }
        }
    }

    // 加载所有类别
    private func loadCategories() {
        FirestoreService().loadCategories(userID: userID, defaultCategories: []) { fetchedCategories in
            DispatchQueue.main.async {
                self.categories = fetchedCategories

                if let firstCategory = fetchedCategories.first {
                    self.selectedCategory = firstCategory
                    loadTreasuresDetail(for: firstCategory)
                }
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
                loadCategories()  // 删除成功后重新加载类别
            }
        }
    }
}

#Preview {
    CategoryView()
}
