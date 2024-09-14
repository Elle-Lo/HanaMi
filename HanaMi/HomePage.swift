import SwiftUI
import FirebaseFirestore
    
    struct HomePage: View {
        @State private var treasures: [Treasure] = []
        @State private var currentTreasures: [Treasure] = []
        @State private var isLoading = false
        @State private var showMenu = false
        
        private let db = Firestore.firestore()
        
        var body: some View {
            NavigationView {
                ZStack {
                   
                    Image("Homebg")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                    
                    Color.black.opacity(0.2).edgesIgnoringSafeArea(.all)
                    
                    MenuButton(showMenu: $showMenu)
                        .zIndex(2)
                    
                    VStack() {
                        
                        Spacer().frame(height: 5)
                        
                        if isLoading {
                            ProgressView("加载宝藏中...")
                        } else {
                            ForEach(currentTreasures) { treasure in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("类别: \(treasure.category)")
                                    Text("创建时间: \(treasure.createdTime, style: .date)")
                                    Text("位置: \(treasure.latitude), \(treasure.longitude)")
                                    
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
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 100)
                    
                    VStack {
                        Spacer()

                        HStack(spacing: 20) {
                          
                            NavigationLink(destination: DepositPage()) {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                fetchRandomTreasures()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.bottom, 30)
                    }

                    if showMenu {
                        Menu(showMenu: $showMenu)
                            .transition(.move(edge: .leading))
                            .animation(.easeInOut, value: showMenu)
                            .zIndex(1)
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
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
