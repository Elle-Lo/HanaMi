import SwiftUI
import Kingfisher

struct CategoryCardView: View {
    @StateObject private var viewModel: CategoryCardViewModel
    var onDelete: () -> Void
    var onCategoryChange: (_ newCategory: String) -> Void

    init(treasure: Treasure, userID: String, onDelete: @escaping () -> Void, onCategoryChange: @escaping (_ newCategory: String) -> Void) {
        _viewModel = StateObject(wrappedValue: CategoryCardViewModel(treasure: treasure, userID: userID))
        self.onDelete = onDelete
        self.onCategoryChange = onCategoryChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶部 HStack，包含 ToggleButton 和 CategorySelectionView
            HStack(alignment: .top) {
                ToggleButton(isPublic: $viewModel.isPublic)
                    .onChange(of: viewModel.isPublic) { _ in
                        viewModel.updateTreasureFields()
                    }

                CategorySelectionView(
                    selectedCategory: $viewModel.selectedCategory,
                    categories: $viewModel.categories,
                    userID: viewModel.userID
                )
                .onChange(of: viewModel.selectedCategory) { newCategory in
                    viewModel.updateTreasureFields()
                    onCategoryChange(newCategory)
                }
                .onAppear {
                    viewModel.loadCategories()
                }

                Spacer()

                Button(action: {
                    viewModel.showTreasureDeleteAlert = true
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
                Text("\(viewModel.treasure.longitude), \(viewModel.treasure.latitude)")
                    .font(.caption)
                    .foregroundColor(.black)
            }
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)

            Divider()
                .padding(.vertical, 10)

            // 显示宝藏内容
            ForEach(viewModel.treasure.contents.sorted(by: { $0.index < $1.index })) { content in
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
                            LinkPreviewView(url: url)
                                .cornerRadius(10)  // 保持圆角
                                .shadow(radius: 5)  // 阴影
                                .padding(.vertical, 5)  // 垂直间距

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
        // 使用新的 alert 语法
        .alert("確認删除嗎？", isPresented: $viewModel.showTreasureDeleteAlert) {
            Button("確認", role: .destructive) {
                viewModel.deleteTreasure { success in
                    if success {
                        onDelete()
                    }
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("確認删除這項寶藏嗎？這個動作無法撤回！")
        }
//        .id(viewModel.selectedCategory)  
    }
       
}
