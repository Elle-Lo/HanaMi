import SwiftUI
import FirebaseFirestore

struct HomePage: View {
    @State private var treasures: [Treasure] = []
    @State private var currentTreasures: [Treasure] = []
    @State private var isLoading = false

    private let db = Firestore.firestore()

    var body: some View {
        // 创建一个全新的 NavigationView，开始新的导航系统
        NavigationView {
            ZStack {
                // 背景图像
                Image("Homebg")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                // 添加半透明黑色遮罩
                Color.black.opacity(0.2).edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Spacer() // 将内容推到底部

                    // 如果正在加载，显示加载指示器
                    if isLoading {
                        ProgressView("加载宝藏中...")
                    } else {
                        // 显示当前的宝藏
                        ForEach(currentTreasures) { treasure in
                            VStack {
                                Text("类别: \(treasure.category)")
                                Text("创建时间: \(treasure.createdTime, style: .date)")
                                Text("位置: \(treasure.latitude), \(treasure.longitude)")
                                
                                // 显示 contents 的内容
                                ForEach(treasure.contents) { content in
                                    if content.type == "image" {
                                        AsyncImage(url: URL(string: content.content)) { image in
                                            image.resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 150, height: 150)
                                        .cornerRadius(15)
                                    } else if content.type == "text" {
                                        Text(content.content)
                                            .padding()
                                            .background(Color.white.opacity(0.4))
                                            .cornerRadius(15)
                                    }
                                }
                            }
                            .font(.title2)
                            .padding()
                            .background(Color.white.opacity(0.4))
                            .cornerRadius(15)
                        }
                    }

                    // 刷新按钮
                    Button(action: {
                        fetchRandomTreasures()
                    }) {
                        Text("刷新宝藏")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: menuButton, trailing: storageButton) // 自定义导航栏按钮
        }
        .navigationViewStyle(StackNavigationViewStyle()) // 强制单层导航视图
    }

    // 自定义清单按钮
    var menuButton: some View {
        Button(action: {
            print("清单按钮点击")
        }) {
            Image(systemName: "line.horizontal.3")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.3))
                .cornerRadius(10)
        }
    }

    // 自定义储存按钮
    var storageButton: some View {
        NavigationLink(destination: DepositPage()) {
            Image(systemName: "shippingbox")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.3))
                .cornerRadius(10)
        }
    }

    // 按需从 Firestore 获取随机宝藏数据
    func fetchRandomTreasures() {
        isLoading = true
        currentTreasures.removeAll()

        // 从 Firestore 获取随机的 3 条宝藏数据
        db.collection("Treasures")
            .limit(to: 3)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("获取宝藏数据时出错: \(error)")
                    isLoading = false
                    return
                }

                // 遍历每个宝藏文档
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let id = document.documentID
                    let category = data["category"] as? String ?? ""
                    let createdTime = (data["createdTime"] as? Timestamp)?.dateValue() ?? Date()
                    let isPublic = data["isPublic"] as? Bool ?? false
                    let location = data["location"] as? GeoPoint
                    let latitude = location?.latitude ?? 0
                    let longitude = location?.longitude ?? 0

                    // 获取子集合 contents
                    db.collection("Treasures").document(id).collection("contents").getDocuments { (contentSnapshot, contentError) in
                        if let contentError = contentError {
                            print("获取内容数据时出错: \(contentError)")
                            isLoading = false
                            return
                        }

                        var contents: [TreasureContent] = []
                        for contentDoc in contentSnapshot!.documents {
                            let contentData = contentDoc.data()
                            let contentType = contentData["type"] as? String ?? ""
                            let contentValue = contentData["content"] as? String ?? ""
                            contents.append(TreasureContent(id: contentDoc.documentID, type: contentType, content: contentValue))
                        }

                        // 将完整的 treasure 和 contents 添加到数组中
                        let treasure = Treasure(id: id, category: category, createdTime: createdTime, isPublic: isPublic, latitude: latitude, longitude: longitude, contents: contents)
                        currentTreasures.append(treasure)

                        isLoading = false
                    }
                }
            }
    }
}

#Preview {
    HomePage()
}
