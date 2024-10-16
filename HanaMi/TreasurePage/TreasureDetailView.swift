import SwiftUI
import FirebaseFirestore
import Kingfisher
import AVKit

struct TreasureDetailView: View {
    let treasure: Treasure
    @State private var isPlayingAudio = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showImageViewer = false
    @State private var selectedImageURL: URL?
    @State private var isPlayingHeartAnimation = false  // 控制心形動畫播放
    @State private var isFavorite = false
    @State private var collectionTreasureList: [String] = []
    @State private var showReportAlert = false
    @State private var reportReason = ""
    @State private var showMenu = false // 控制 Menu 的顯示
    @State private var isLoading = true  // 控制載入動畫的狀態
    @State private var isPlayingAnimation = false  // 控制動畫播放
    
    private let firestoreService = FirestoreService()

    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }

    var body: some View {
        
        ZStack {
            ZStack(alignment: .leading) {
                Color(.colorYellow)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 顯示日期
                        HStack {
                            // 顯示日期
                            Text(treasure.createdTime, formatter: dateFormatter)
                                .font(.custom("LexendDeca-SemiBold", size: 18))
                                .foregroundColor(.colorBrown)
                                .bold()
                            
                            Spacer()
                            
                            // Menu 按鈕
                            Menu {
                                Button("檢舉", role: .none) {
                                    showReportAlert = true
                                }
                                Button("封鎖", role: .destructive) {
                                    blockUser()
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18)) // 調小按鈕圖示大小
                                    .foregroundColor(.black)
                                    .padding(8) // 控制內部間距
                                    .background(Color.clear)
                            }
                            .frame(width: 30, height: 30) // 控制按鈕大小
                        }
                            // 公開狀態、類別和地點
                            HStack(spacing: 8) {
                                if treasure.isPublic {
                                    Text("公開")
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .font(.custom("LexendDeca-SemiBold", size: 15))
                                        .background(Color.colorYellow)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.colorBrown, lineWidth: 2)
                                        )
                                        .foregroundColor(.colorBrown)
                                        .bold()
                                } else {
                                    Text("私人")
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 18)
                                        .font(.custom("LexendDeca-SemiBold", size: 15))
                                        .background(Color.colorBrown)
                                        .cornerRadius(10)
                                        .foregroundColor(.colorYellow)
                                        .bold()
                                }
                                
                                Text(treasure.category)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 18)
                                    .background(Color(hex: "D4D4D4").opacity(0.9))
                                    .cornerRadius(10)
                                    .foregroundColor(.colorYellow)
                                    .font(.custom("LexendDeca-SemiBold", size: 15))
                            }
                            .padding(.leading, 2)
                            
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.colorBrown)
                                Text(treasure.locationName)
                                    .foregroundColor(.colorBrown)
                                    .font(.custom("LexendDeca-SemiBold", size: 10))
                            }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .background(Color(hex: "E8E8E8").opacity(0.75))
                        .cornerRadius(10)
                        .bold()
                        
                        // Media (圖片、影片、連結) 顯示
                        let mediaContents = treasure.contents.filter { $0.type == .image || $0.type == .video || $0.type == .link }
                        
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
                                            }
                                        default:
                                            EmptyView()
                                        }
                                    }
                                }
                            }
                            .frame(height: 300)
                            .cornerRadius(8)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: mediaContents.count > 1 ? .always : .never))
                        }
                        
                        // 音訊內容單獨處理
                        if let audioContent = treasure.contents.first(where: { $0.type == .audio }) {
                            if let audioURL = URL(string: audioContent.content) {
                                AudioPlayerView(audioURL: audioURL)
                                    .frame(height: 100)
                                    .padding(.top, 10)
                                    .padding(.bottom, 20)
                            }
                        }
                        
                        // 文字內容
                        if let textContent = treasure.contents.first(where: { $0.type == .text })?.content {
                                Text(textContent)
                                    .font(.custom("LexendDeca-Regular", size: 16))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 5)
                                    .lineSpacing(10.0)
                                    .padding(.top, mediaContents.isEmpty ? 0 : 10) // 如果沒有媒體，則不留間距

                        }
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 110)
                .padding(.horizontal, 20)
                
            }
            
            
            // 收藏按鈕及動畫顯示
                        VStack {
                            Spacer()

                            // Lottie 動畫
                            if isPlayingHeartAnimation {
                                LottieView(animationFileName: "heart", isPlaying: $isPlayingHeartAnimation)
                                    .frame(width: 140, height: 140)
                                    .offset(y: 40)  // 調整動畫在按鈕上方的位置
                                    .scaleEffect(0.9)  // 調整動畫大小
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            isPlayingHeartAnimation = false
                                        }
                                    }
                            }

                            // 收藏按鈕
                            Button(action: {
                                isPlayingHeartAnimation = true  // 直接觸發動畫播放
                                addTreasureToFavorites()
                            }) {
                                Image("treasure")
                                    .font(.system(size: 30))
                                    .foregroundColor(.colorBrown)
                                    .padding()
                                    .background(Color.white.opacity(0.6))
                                    .cornerRadius(50)
                                    .shadow(radius: 10)
                            }
                            .padding(.bottom, 30)
                        }
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(alertMessage))
                    }
                    .alert("檢舉此寶藏", isPresented: $showReportAlert) {
                        TextField("請輸入檢舉原因", text: $reportReason)
                        Button("送出", action: submitReport)
                        Button("取消", role: .cancel) {}
                    }
                    .onAppear {
                        fetchUserFavorites()
                            }
                }

    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd (E)"
        return formatter
    }
    
    private func fetchUserFavorites() {
           firestoreService.fetchFavoriteTreasures(userID: userID) { result in
               switch result {
               case .success(let treasures):
                   collectionTreasureList = treasures.map { $0.id ?? "" }
                   isFavorite = collectionTreasureList.contains(treasure.id ?? "")
               case .failure(let error):
                   print("無法取得收藏寶藏：\(error.localizedDescription)")
               }
           }
       }

       private func handleFavoriteAction() {
           if collectionTreasureList.contains(treasure.id ?? "") {
               alertMessage = "此寶藏已在收藏中"
               showAlert = true
           } else {
               isPlayingHeartAnimation = true
               addTreasureToFavorites()
           }
       }
    
    private func addTreasureToFavorites() {
        // 先檢查該寶藏是否已經在收藏列表中
        guard !collectionTreasureList.contains(treasure.id ?? "") else {
            alertMessage = "此寶藏已在收藏中"
            showAlert = true
            isPlayingHeartAnimation = false
            return
        }

        // 若未收藏，才進行 Firebase 的存取操作
        firestoreService.addTreasureToFavorites(userID: userID, treasureID: treasure.id ?? "") { result in
            switch result {
            case .success:
                collectionTreasureList.append(treasure.id ?? "")
                isFavorite = true
            case .failure(let error):
                alertMessage = "添加寶藏到收藏失敗：\(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    private func submitReport() {
            guard !reportReason.trimmingCharacters(in: .whitespaces).isEmpty else {
                print("檢舉原因不可為空")
                return
            }
            let report = Report(
                reason: reportReason,
                reporter: userID,
                reportedUser: treasure.userID
            )
            firestoreService.reportUser(report: report) { result in
                switch result {
                case .success:
                    print("檢舉已成功送出")
                case .failure(let error):
                    print("檢舉失敗：\(error.localizedDescription)")
                }
            }
        }
    
    private func blockUser() {
        firestoreService.blockUser(currentUserID: userID, blockedUserID: treasure.userID) { result in
            switch result {
            case .success:
                print("已成功封鎖該使用者")
                // 可根據需求更新 UI 或跳轉頁面，避免繼續顯示該用戶的寶藏
            case .failure(let error):
                print("封鎖失敗：\(error.localizedDescription)")
            }
        }
    }
}
