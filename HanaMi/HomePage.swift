import SwiftUI
import FirebaseFirestore
import MapKit

struct HomePage: View {
    @State private var treasures: [Treasure] = []
    @State private var currentTreasures: [Treasure] = []
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

                    // 加载指示器
                    if isLoading {
                        ProgressView("加载宝藏中...")
                    } else {
                        // 顯示内容的 ScrollView，允许滑动
                        ScrollView {
                            ForEach(currentTreasures) { treasure in
                                TreasureCardView(treasure: treasure)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.top, 15) 

                // 刷新按鈕，固定在右下角
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

struct TreasureCardView: View {
    var treasure: Treasure

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(treasure.category)
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 10)

            Text("地點: \(treasure.locationName)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Divider()
                .padding(.vertical, 5)

            // 依照順序顯示 TreasureContents
            ForEach(treasure.contents) { content in
                VStack(alignment: .leading, spacing: 10) {
                    switch content.type {
                    case .text:
                        Text(content.content)
                            .font(.body)
                            .foregroundColor(.black)

                    case .image:
                        if let imageURL = URL(string: content.content) {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(maxWidth: .infinity)
                            .cornerRadius(10)
                        }

                    case .link:
                        if let url = URL(string: content.content) {
                            Link(destination: url) {
                                Text(content.displayText ?? "点击打开链接")
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                        }

                    default:
                        EmptyView() // 处理其他类型
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
