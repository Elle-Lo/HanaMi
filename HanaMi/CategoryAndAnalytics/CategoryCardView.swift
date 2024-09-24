import SwiftUI
import FirebaseFirestore
import Kingfisher

struct CategoryCardView: View {
    let treasure: Treasure
    @State private var showingDeleteAlert = false
    @State private var categories: [String] = []
    @State private var isPublic: Bool
    @State private var selectedCategory: String

    var firestoreService = FirestoreService()
    let userID: String
    var onDelete: () -> Void
    var onCategoryChange: () -> Void  // 新增的回调 closure

    init(treasure: Treasure, userID: String, onDelete: @escaping () -> Void, onCategoryChange: @escaping () -> Void) {
        self.treasure = treasure
        self.userID = userID
        self.onDelete = onDelete
        self.onCategoryChange = onCategoryChange  // 初始化
        _isPublic = State(initialValue: treasure.isPublic)
        _selectedCategory = State(initialValue: treasure.category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶部 HStack，包含 ToggleButton 和 CategorySelectionView
            HStack(alignment: .top) {
                ToggleButton(isPublic: $isPublic)
                    .onChange(of: isPublic) { newValue in
                        if let treasureID = treasure.id {
                            firestoreService.updateTreasureFields(
                                userID: userID,
                                treasureID: treasureID,
                                category: selectedCategory,
                                isPublic: newValue
                            ) { success in
                                // 可根据需要处理更新结果
                            }
                        }
                    }

                CategorySelectionView(
                    selectedCategory: $selectedCategory,
                    categories: $categories,
                    userID: userID
                )
                .onChange(of: selectedCategory) { newCategory in
                    if let treasureID = treasure.id {
                        firestoreService.updateTreasureFields(
                            userID: userID,
                            treasureID: treasureID,
                            category: newCategory,
                            isPublic: isPublic
                        ) { success in
                            if success {
                                // 调用回调，通知父视图
                                onCategoryChange()
                            }
                        }
                    }
                }
                .onAppear {
                    loadCategories()
                }

                Spacer()

                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(.red)
                        .padding(.trailing, 5)
                        .padding(.top, 5)
                }
            }
            .padding(.top, 5)

            // 显示经纬度
            HStack(spacing: 4) {
                Image("pin")
                    .resizable()
                    .frame(width: 10, height: 10)
                Text("\(treasure.longitude), \(treasure.latitude)")
                    .font(.caption)
                    .foregroundColor(.black)
            }
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)

            Divider()
                .padding(.vertical, 10)

            // 显示宝藏内容
            ForEach(treasure.contents.sorted(by: { $0.index < $1.index })) { content in
                VStack(alignment: .leading, spacing: 10) {
                    switch content.type {
                    case .text:
                        Text(content.content)
                            .font(.body)
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)

                    case .image:
                        if let imageURL = URL(string: content.content) {
                            KFImage(imageURL)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(10)
                        }

                    case .link:
                        if let url = URL(string: content.content) {
                            Text(content.displayText ?? url.absoluteString)
                                .font(.body)
                                .foregroundColor(.blue)
                                .underline()
                                .onTapGesture {
                                    UIApplication.shared.open(url)
                                }
                        }

                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, 5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("确认删除"),
                message: Text("确定要删除这个宝藏吗？这个操作无法撤销。"),
                primaryButton: .destructive(Text("删除")) {
                    deleteTreasure()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }

    private func loadCategories() {
        firestoreService.loadCategories(userID: userID, defaultCategories: []) { fetchedCategories in
            self.categories = fetchedCategories
        }
    }

    private func deleteTreasure() {
        guard let treasureID = treasure.id else {
            print("Error: Treasure ID is nil. Cannot delete.")
            return
        }

        firestoreService.deleteSingleTreasure(userID: userID, treasureID: treasureID) { result in
            switch result {
            case .success:
                print("Treasure successfully deleted")
                onDelete()
            case .failure(let error):
                print("Error deleting treasure: \(error)")
            }
        }
    }
}
