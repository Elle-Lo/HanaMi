import SwiftUI
import FirebaseFirestore

struct HomePage: View {
    @State private var treasures: [Treasure] = []
    @State private var currentTreasures: [Treasure] = []
    @State private var isLoading = false

    private let db = Firestore.firestore()
    private let userId = "currentUserId"

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
                                        .frame(width: 50, height: 50) // 设置圆形背景
                                        .opacity(0.3) // 半透明背景
                                )
                        }
                        .padding(.trailing, 30) // 從右邊有適當的距離
                        .padding(.bottom, 70) // 從底部移動一點，避免被 TabView 擋住
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            fetchRandomTreasures()
        }
    }

    // 按需从 Firestore 获取用户的 Treasure 数据
    func fetchRandomTreasures() {
        isLoading = true
        currentTreasures.removeAll()

        db.collection("Users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let treasureList = data?["treasureList"] as? [String] ?? []

                let treasureCollection = db.collection("Treasures")
                let dispatchGroup = DispatchGroup()

                for treasureId in treasureList {
                    dispatchGroup.enter()

                    treasureCollection.document(treasureId).getDocument { (treasureDoc, error) in
                        if let treasureData = treasureDoc?.data() {
                            let id = treasureDoc?.documentID ?? ""
                            let category = treasureData["category"] as? String ?? ""
                            let createdTime = (treasureData["createdTime"] as? Timestamp)?.dateValue() ?? Date()
                            let isPublic = treasureData["isPublic"] as? Bool ?? false
                            let location = treasureData["location"] as? GeoPoint
                            let latitude = location?.latitude ?? 0
                            let longitude = location?.longitude ?? 0
                            let locationName = treasureData["locationName"] as? String ?? ""

                            treasureCollection.document(id).collection("contents").getDocuments { (contentSnapshot, contentError) in
                                var contents: [TreasureContent] = []
                                if let contentDocuments = contentSnapshot?.documents {
                                    for contentDoc in contentDocuments {
                                        let contentData = contentDoc.data()
                                        let contentTypeInt = contentData["type"] as? Int ?? 0
                                        let contentType = ContentType(rawValue: contentTypeInt) ?? .text
                                        let contentValue = contentData["content"] as? String ?? ""
                                        contents.append(TreasureContent(id: contentDoc.documentID, type: contentType, content: contentValue))
                                    }
                                }

                                let treasure = Treasure(id: id, category: category, createdTime: createdTime, isPublic: isPublic, latitude: latitude, longitude: longitude, locationName: locationName, contents: contents)
                                currentTreasures.append(treasure)

                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    isLoading = false
                }

            } else {
                print("用户文档不存在或出错: \(error?.localizedDescription ?? "")")
                isLoading = false
            }
        }
    }
}

#Preview {
    HomePage()
}
