import SwiftUI
import FirebaseFirestore
import Kingfisher
//import AVFoundation

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
        ZStack {
            
            // 半透明黑色遮罩
            Color.black.opacity(0.2).edgesIgnoringSafeArea(.all)
            
            VStack {
                if isLoading {
                    ProgressView("加載中...")
                } else {
                    ScrollView {
                        ForEach(treasures) { treasure in
                            TreasureCardView(treasure: treasure)
                                .padding(.vertical, 20)
                        }
                    }
                    .padding(.horizontal, 30)
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
        .background(
            Group {
                if let backgroundImageUrl = backgroundImageUrl, !isUsingDefaultBackground {
                    KFImage(backgroundImageUrl)
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all) // 背景延伸到安全区域外
                } else {
                    Image("Homebg")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all) // 使用默认背景
                }
            }
        )
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
