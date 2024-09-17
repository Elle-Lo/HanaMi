import SwiftUI
import FirebaseFirestore
import MapKit

struct HomePage: View {
    @State private var treasures: [Treasure] = []
    @State private var currentTreasures: [Treasure] = []
    @State private var isLoading = false

    private let userId = "currentUserId"
    private let firestoreService = FirestoreService() // 实例化 FirestoreService

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
                    Spacer().frame(height: 5)

                    // 加载指示器
                    if isLoading {
                        ProgressView("加载宝藏中...")
                    } else {
                        // 顯示內容的 ScrollView
                        ScrollView {
                            ForEach(currentTreasures) { treasure in
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(treasure.contents) { content in
                                        VStack {
                                            switch content.type {
                                            case .text:
                                                Text(content.content)
                                                    .padding()
                                                    .background(Color.white.opacity(0.4))
                                                    .cornerRadius(15)

                                            case .image:
                                                AsyncImage(url: URL(string: content.content)) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                } placeholder: {
                                                    ProgressView()
                                                }
                                                .frame(width: 300, height: 200)
                                                .cornerRadius(15)

                                            case .link:
                                                Link(destination: URL(string: content.content)!) {
                                                    Text("点击打开链接")
                                                }
                                                .padding()
                                                .background(Color.white.opacity(0.4))
                                                .cornerRadius(15)

                                            default:
                                                EmptyView() // 其他類型尚未處理
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 20)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.4))
                                .cornerRadius(15)
                                .padding(.bottom, 10)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 100)

                // 刷新按鈕，固定在右下角靠上一點
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
                                .background(
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 50, height: 50)
                                        .opacity(0.3)
                                )
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 70)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            fetchRandomTreasures()
        }
    }

    // 调用 FirestoreService 获取随机宝藏数据
    func fetchRandomTreasures() {
        isLoading = true
        currentTreasures.removeAll()

        firestoreService.fetchRandomTreasures(userID: userId) { result in
            switch result {
            case .success(let treasures):
                currentTreasures = treasures
            case .failure(let error):
                print("获取宝藏失败: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}

#Preview {
    HomePage()
}
