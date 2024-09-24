import SwiftUI
import FirebaseFirestore

struct CategoryView: View {
    @State private var categories: [String] = []
    @State private var selectedCategory: String?
    @State private var treasures: [Treasure] = []
    @State private var isAddingCategory = false  // 是否顯示添加類別的彈窗
    @State private var newCategoryName = ""      // 存儲新類別的名稱
    @State private var showEditOptions = false   // 是否顯示編輯選項
    @State private var showDeleteAlert = false   // 是否顯示刪除確認框
    @State private var showChangeNameAlert = false  // 是否顯示更改名稱的彈窗
    @State private var editedCategoryName = ""   // 修改後的新類別名稱
    private var userID: String = "g61HUemIJIRIC1wvvIqa"

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                // 類別標題
                Text("Category")
                    .font(.largeTitle)
                    .bold()
                    .padding([.top, .leading])
                
                // 類別 Collection View
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        // "All" 按鈕 - 放在第一個
                        Button(action: {
                            selectedCategory = "All"
                            loadAllTreasures()  // 加載所有寶藏
                        }) {
                            Text("All")
                                .padding(.vertical, 13)
                                .padding(.horizontal, 18)
                                .background(selectedCategory == "All" ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == "All" ? Color.white : Color.black)
                                .cornerRadius(25)
                        }
                        
                        // 其餘的動態加載類別按鈕
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                loadTreasuresDetail(for: category)  // 加載該類別的寶藏
                            }) {
                                Text(category)
                                    .padding(.vertical, 13)
                                    .padding(.horizontal, 18)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == category ? Color.white : Color.black)
                                    .cornerRadius(25)
                            }
                        }
                        
                        // 添加新類別按鈕，帶有加號圖標
                        Button(action: {
                            isAddingCategory = true  // 顯示添加類別的彈窗
                        }) {
                            Label("Add Category", systemImage: "plus")  // 使用系統圖標
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
                
                // 顯示添加類別的對話框
                .sheet(isPresented: $isAddingCategory) {
                    VStack(spacing: 15) {  // 控制垂直間距
                        Text("新增類別")
                            .font(.headline)
                            .padding(.top, 10)  // 控制標題和頂部的間距
                        
                        TextField("輸入新類別名稱", text: $newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)  // 控制 TextField 的寬度
                            .padding(.horizontal, 20)
                        
                        Button("添加類別") {
                            FirestoreService().addCategory(userID: userID, category: newCategoryName) { success in
                                if success {
                                    loadCategories()  // 刷新類別列表
                                    isAddingCategory = false  // 關閉彈窗
                                }
                            }
                        }
                        .frame(width: 100)
                        .disabled(newCategoryName.isEmpty)
                    }
                    .padding()
                    .frame(width: 300, height: 300)
                }
                
                // 類別下的寶藏列表
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
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                        }
                    }
                }
                .frame(maxWidth: .infinity)  // ScrollView 占滿可用寬度
                .ignoresSafeArea(edges: .horizontal)
                .background(Color.clear)
            }
            .onAppear {
                loadCategories() // 頁面加載時加載類別
            }
            
            // 在右下角添加編輯按鈕（若選中的不是 "All" 和 "Add Category" 時顯示）
            if selectedCategory != "All" && selectedCategory != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showEditOptions = true  // 顯示編輯選項
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
        
        // 彈出操作選項
        .actionSheet(isPresented: $showEditOptions) {
            ActionSheet(
                title: Text("編輯類別"),
                buttons: [
                    .destructive(Text("刪除類別")) {
                        showDeleteAlert = true  // 顯示刪除確認框
                    },
                    .default(Text("更改名稱")) {
                        showChangeNameAlert = true  // 顯示更改名稱輸入框
                    },
                    .cancel()
                ]
            )
        }
        
        // 刪除類別確認框
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("刪除類別"),
                message: Text("您確認要刪除該類別及其所有寶藏嗎？"),
                primaryButton: .destructive(Text("確認")) {
                    if let category = selectedCategory {
                        deleteCategory(category)  // 刪除類別及所有寶藏
                    }
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        
        // 更改名稱彈窗
        .alert("更改類別名稱", isPresented: $showChangeNameAlert) {
            TextField("新類別名稱", text: $editedCategoryName)
            Button("送出") {
                if !editedCategoryName.isEmpty, let category = selectedCategory {
                    FirestoreService().updateCategoryNameAndTreasures(userID: userID, oldName: category, newName: editedCategoryName) { success in
                               if success {
                                   print("類別名稱和寶藏更新成功")
                                   loadCategories()
                               } else {
                                   print("類別名稱或寶藏更新失敗")
                               }
                           }
                       }
                   }
            
            Button("取消", role: .cancel) { }
        }
    }
    
    // 加載所有類別
    private func loadCategories() {
        FirestoreService().loadCategories(userID: userID, defaultCategories: []) { fetchedCategories in
            self.categories = fetchedCategories
            
            if let firstCategory = fetchedCategories.first {
                self.selectedCategory = firstCategory
                loadTreasuresDetail(for: firstCategory)
            }
        }
    }
    
    // 加載特定類別的寶藏
    private func loadTreasuresDetail(for category: String) {
        FirestoreService().fetchTreasuresForCategory(userID: userID, category: category) { result in
            switch result {
            case .success(let treasures):
                self.treasures = treasures
            case .failure(let error):
                print("Error fetching treasures: \(error.localizedDescription)")
            }
        }
    }
    
    // 加載所有寶藏
    private func loadAllTreasures() {
        FirestoreService().fetchAllTreasures(userID: userID) { result in
            switch result {
            case .success(let treasures):
                self.treasures = treasures
            case .failure(let error):
                print("Error fetching all treasures: \(error.localizedDescription)")
            }
        }
    }
    
    // 刪除選中的類別及其寶藏
    private func deleteCategory(_ category: String) {
        FirestoreService().deleteCategory(userID: userID, category: category) { success in
            if success {
                loadCategories()  // 刪除成功後重新加載類別
            }
        }
    }
    
    // 更改類別名稱
    private func changeCategoryName(_ oldName: String, newName: String) {
        FirestoreService().updateCategoryName(userID: userID, oldName: oldName, newName: newName) { success in
            if success {
                loadCategories()  // 更改成功後重新加載類別
            }
        }
    }
}

#Preview {
    CategoryView()
}
