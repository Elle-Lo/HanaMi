import SwiftUI
import FirebaseFirestore
import Kingfisher

struct HomePage: View {
    @State private var treasures: [Treasure] = []
    @State private var isLoading = false
    @State private var selectedBackgroundImage: UIImage?
    @State private var isUsingDefaultBackground = true
    @State private var backgroundImageUrl: URL?  // 用戶背景圖片 URL
    
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    private let firestoreService = FirestoreService()
    
    var body: some View {
        NavigationView {
            ZStack {

                // 根據選擇的背景圖顯示或使用默認背景
                if let backgroundImageUrl = backgroundImageUrl, !isUsingDefaultBackground {
                    KFImage(backgroundImageUrl)
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Image("Homebg")  // 默認背景圖
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                }
                
                // 半透明黑色遮罩
                Color.black.opacity(0.2).edgesIgnoringSafeArea(.all)

                VStack {
                    if isLoading {
                        ProgressView("加載中...")
                    } else {
                        ScrollView {
                            ForEach(treasures) { treasure in
                                TreasureCardView(treasure: treasure)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                        }
                        .scrollIndicators(.hidden)
                    }

                    Spacer()
                }
                .padding(.top, 15)

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
                   fetchBackgroundImage()  // 加載用戶背景圖片
                   fetchRandomTreasures()
               }
    }
    
    func fetchBackgroundImage() {
            firestoreService.fetchUserBackgroundImage(uid: userID) { imageUrlString in
                if let imageUrlString = imageUrlString, let url = URL(string: imageUrlString) {
                    self.backgroundImageUrl = url
                    self.isUsingDefaultBackground = false  // 使用自定義背景
                } else {
                    self.isUsingDefaultBackground = true  // 沒有背景圖片，使用默認背景
                }
            }
        }
    
    func fetchRandomTreasures() {
        isLoading = true
        firestoreService.fetchRandomTreasures(userID: userID) { result in
            switch result {
            case .success(let fetchedTreasures):
                treasures = fetchedTreasures
            case .failure(let error):
                print("獲取寶藏失敗: \(error.localizedDescription)")
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

            ForEach(treasure.contents.sorted(by: { $0.index < $1.index })) { content in
                VStack(alignment: .leading, spacing: 10) {
                   
                    switch content.type {
                    case .text:
                     
                        Text(content.content)
                            .font(.body)
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true) // 确保文本换行时不会拉伸

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
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

