import SwiftUI
import Kingfisher

struct CategoryCardView: View {
    @Binding var selectedCategory: String?
    @Binding var categories: [String]
    @StateObject private var viewModel: CategoryCardViewModel
    var onDelete: () -> Void
    var onCategoryChange: (_ newCategory: String) -> Void

    init(treasure: Treasure, userID: String, selectedCategory: Binding<String?>, categories: Binding<[String]>, onDelete: @escaping () -> Void, onCategoryChange: @escaping (_ newCategory: String) -> Void) {
        _viewModel = StateObject(wrappedValue: CategoryCardViewModel(treasure: treasure, userID: userID))
        self._selectedCategory = selectedCategory
        self._categories = categories
        self.onDelete = onDelete
        self.onCategoryChange = onCategoryChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
           
            HStack(alignment: .top) {
                ToggleButton(isPublic: $viewModel.isPublic)
                    .onChange(of: viewModel.isPublic) { oldValue, newValue in
                        viewModel.updateTreasureFields()
                    }

                CategorySelectionView(
                    selectedCategory: $viewModel.selectedCategory,
                    categories: $viewModel.categories,
                    userID: viewModel.userID
                )
                .onChange(of: viewModel.selectedCategory) { oldCategory, newCategory in
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
            .padding(.vertical, 5)

            // 顯示經緯度
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

            // 檢查是否有圖片、影片或連結的內容
            let mediaContents = viewModel.treasure.contents.filter { $0.type == .image || $0.type == .video || $0.type == .link }
                       
                       // 如果有圖片、影片、連結，顯示 TabView
                       if !mediaContents.isEmpty {
                           TabView {
                               ForEach(mediaContents.sorted(by: { $0.index < $1.index })) { content in
                                   VStack(alignment: .leading, spacing: 10) {
                                       switch content.type {
                                       case .image:
                                           if let imageURL = URL(string: content.content) {
                                               URLImageViewWithPreview(imageURL: imageURL)
                                           }
                                       case .video:
                                           if let videoURL = URL(string: content.content) {
                                               VideoPlayerView(url: videoURL)
                                                   .scaledToFill()
                                                   .frame(width: 350, height: 300)
                                                   .cornerRadius(8)
                                                   .clipped()
                                           }
                                       case .link:
                                           if let url = URL(string: content.content) {
                                               LinkPreviewView(url: url)
                                                   .cornerRadius(10)
                                                   .shadow(radius: 5)
                                                   .padding(.vertical, 5)
                                           }
                                       default:
                                           EmptyView()
                                       }
                                   }
                               }
                           }
                .frame(height: 300)
                .cornerRadius(8)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: viewModel.treasure.contents.count > 1 ? .always : .never)) // 這裡動態顯示或隱藏頁面指示器
            }

            // 音訊內容單獨處理
            if let audioContent = viewModel.treasure.contents.first(where: { $0.type == .audio }) {
                if let audioURL = URL(string: audioContent.content) {
                    AudioPlayerView(audioURL: audioURL)
                        .frame(height: 100) // 固定音訊播放器高度
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                }
            }

            // 文字內容
            if let textContent = viewModel.treasure.contents.first(where: { $0.type == .text })?.content {
                ScrollView {
                    Text(textContent)
                        .font(.custom("LexendDeca-Regular", size: 16))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .lineSpacing(10.0)
                        .padding(.top, mediaContents.isEmpty ? 0 : 10) // 如果沒有媒體，則不留間距
                }
            }

        }
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.6))
        .cornerRadius(15)
        .shadow(radius: 1)
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
    }
}
