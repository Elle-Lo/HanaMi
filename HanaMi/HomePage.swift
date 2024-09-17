import SwiftUI
import FirebaseFirestore
import Kingfisher

struct HomePage: View {
    @State private var treasures: [Treasure] = []
    @State private var isLoading = false

    private let userId = "g61HUemIJIRIC1wvvIqa" // 假设的用户ID
    private let firestoreService = FirestoreService()

    var body: some View {
        NavigationView {
            ZStack {
                // 背景圖片
                Image("Homebg")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                // 半透明黑色遮罩
                Color.black.opacity(0.2).edgesIgnoringSafeArea(.all)

                VStack {
                    if isLoading {
                        ProgressView("加载宝藏中...")
                    } else {
                        ScrollView {
                            ForEach(treasures) { treasure in
                                TreasureCardView(treasure: treasure)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.top, 15)

                // 刷新按鈕
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            fetchRandomTreasures()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.gray).frame(width: 50, height: 50).opacity(0.3))
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 70)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            fetchRandomTreasures() // 打开页面时调用
        }
    }

    func fetchRandomTreasures() {
        isLoading = true
        firestoreService.fetchRandomTreasures(userID: userId) { result in
            switch result {
            case .success(let fetchedTreasures):
                treasures = fetchedTreasures
            case .failure(let error):
                print("获取宝藏失败: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}


struct TreasureCardView: View {
    var treasure: Treasure

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 显示分类
            Text(treasure.category)
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 10)  // 控制顶部的 padding

            Text("地點: \(treasure.locationName)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Divider()
                .padding(.vertical, 5)

            // 循环展示内容，按 index 排序
            ForEach(treasure.contents.sorted(by: { $0.index < $1.index })) { content in
                VStack(alignment: .leading, spacing: 10) {
                    // 根据内容类型展示不同的内容
                    switch content.type {
                    case .text:
                        // 显示文本
                        Text(content.content)
                            .font(.body)
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true) // 确保文本换行时不会拉伸

                    case .image:
                        // 显示图片
                        if let imageURL = URL(string: content.content) {
                            KFImage(imageURL)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(10)
                        }

                    case .link:
                        // 显示可点击的链接文本
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
                        EmptyView() // 默认情况不展示任何内容
                    }
                }
                .padding(.bottom, 5) // 控制每个内容块之间的底部空间
            }
        }
        .padding() // 整个卡片的 padding
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

