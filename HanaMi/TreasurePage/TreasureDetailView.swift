import SwiftUI
import FirebaseFirestore
import Kingfisher
import AVKit

struct TreasureDetailView: View {
    let treasure: Treasure
    @State private var isPlayingAudio = false
    @State private var alertState = AlertState()
    @State private var showImageViewer = false
    @State private var selectedImageURL: URL?
    @State private var isPlayingHeartAnimation = false
    @State private var isPlayingLoadingAnimation = true
    @State private var isFavorite = false
    @State private var collectionTreasureList: [String] = []
    @State private var showReportAlert = false
    @State private var reportReason = ""
    @State private var isLoading = true
    
    private let firestoreService = FirestoreService()

    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }

    var body: some View {
            ZStack {
                Color(.colorYellow).edgesIgnoringSafeArea(.all)

                if isLoading {
                    LottieView(animationFileName: "walking", loopMode: .loop, isPlaying: $isPlayingLoadingAnimation)
                        .frame(width: 140, height: 140)
                        .offset(y: 550)
                        .scaleEffect(0.3)
                        .onAppear {
                            isPlayingLoadingAnimation = true
                        }
                        .onDisappear {
                            isPlayingLoadingAnimation = false
                        }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            headerView
                            CategoryBadgeView(isPublic: treasure.isPublic, category: treasure.category)
                            locationView
                            mediaContentView
                            audioContentView
                            textContentView
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 110)
                        .padding(.horizontal, 20)
                    }
                    
                    VStack {
                        Spacer()
                        AddToFavoriteButton(isPlayingHeartAnimation: $isPlayingHeartAnimation, action: handleFavoriteAction)
                            .padding(.bottom, 30)
                    }
                }
            }
            .alert(isPresented: $alertState.isPresented) {
                Alert(title: Text(alertState.message))
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
    
    var headerView: some View {
        HStack {
            Text(treasure.createdTime, formatter: dateFormatter)
                .font(.custom("LexendDeca-SemiBold", size: 18))
                .foregroundColor(.colorBrown)
                .bold()
            Spacer()
            OptionsMenu(reportAction: {
                showReportAlert = true
            }, blockAction: {
                blockUser()
            })
        }
    }
    
    var locationView: some View {
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
    }
    
    var mediaContentView: some View {
        let mediaContents = treasure.contents.filter { $0.type == .image || $0.type == .video || $0.type == .link }
        if !mediaContents.isEmpty {
            return AnyView(
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
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    var audioContentView: some View {
        if let audioContent = treasure.contents.first(where: { $0.type == .audio }), let audioURL = URL(string: audioContent.content) {
            return AnyView(
                AudioPlayerView(audioURL: audioURL)
                    .frame(height: 100)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
            )
        }
        return AnyView(EmptyView())
    }
    
    var textContentView: some View {
        if let textContent = treasure.contents.first(where: { $0.type == .text })?.content {
            return AnyView(
                Text(textContent)
                    .font(.custom("LexendDeca-Regular", size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 5)
                    .lineSpacing(10.0)
                    .padding(.top, 10)
            )
        }
        return AnyView(EmptyView())
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd (E)"
        return formatter
    }
    
    private func fetchUserFavorites() {
        firestoreService.fetchFavoriteTreasures(userID: userID) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let treasures):
                    collectionTreasureList = treasures.map { $0.id ?? "" }
                    isFavorite = collectionTreasureList.contains(treasure.id ?? "")
                case .failure(let error):
                    print("無法取得收藏寶藏：\(error.localizedDescription)")
                }
            }
        }
    }
    
//    private func loadTreasureData() {
//            // 模擬數據加載延遲，可以替換成真實的數據加載邏輯
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                // 假設數據加載完成後
//                self.isLoading = false
//            }
//        }
    
    private func handleFavoriteAction() {
        if collectionTreasureList.contains(treasure.id ?? "") {
            showAlert(message: "此寶藏已在收藏中")
        } else {
            isPlayingHeartAnimation = true
            addTreasureToFavorites()
        }
    }
    
    private func addTreasureToFavorites() {
        guard !collectionTreasureList.contains(treasure.id ?? "") else {
            showAlert(message: "此寶藏已在收藏中")
            isPlayingHeartAnimation = false
            return
        }

        firestoreService.addTreasureToFavorites(userID: userID, treasureID: treasure.id ?? "") { result in
            switch result {
            case .success:
                collectionTreasureList.append(treasure.id ?? "")
                isFavorite = true
            case .failure(let error):
                showAlert(message: "添加寶藏到收藏失敗：\(error.localizedDescription)")
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
            case .failure(let error):
                print("封鎖失敗：\(error.localizedDescription)")
            }
        }
    }

    private func showAlert(message: String) {
        alertState = AlertState(isPresented: true, message: message)
    }
}

struct CategoryBadgeView: View {
    let isPublic: Bool
    let category: String
    
    var body: some View {
        HStack(spacing: 8) {
            if isPublic {
                BadgeView(text: "公 開", backgroundColor: .colorYellow, textColor: .colorBrown)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.colorBrown, lineWidth: 2)
                            .background(Color.colorYellow.cornerRadius(10)) // 使用背景顏色並設置圓角
                    )
            } else {
                BadgeView(text: "私 人", backgroundColor: .colorBrown, textColor: .colorYellow)
            }
            BadgeView(text: category, backgroundColor: Color(hex: "D4D4D4").opacity(0.9), textColor: .colorYellow)
        }
    }
}

struct BadgeView: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color

    var body: some View {
        Text(text)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(backgroundColor)
            .cornerRadius(10)
            .foregroundColor(textColor)
            .font(.custom("LexendDeca-SemiBold", size: 15))
            .bold()
    }
}

struct AlertState {
    var isPresented: Bool = false
    var message: String = ""
}

struct OptionsMenu: View {
    let reportAction: () -> Void
    let blockAction: () -> Void

    var body: some View {
        Menu {
            Button("檢舉", role: .none, action: reportAction)
            Button("封鎖", role: .destructive, action: blockAction)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18))
                .foregroundColor(.black)
                .padding(8)
                .background(Color.clear)
        }
        .frame(width: 30, height: 30)
    }
}

struct AddToFavoriteButton: View {
    @Binding var isPlayingHeartAnimation: Bool
    let action: () -> Void

    var body: some View {
        VStack {
            if isPlayingHeartAnimation {
                LottieView(animationFileName: "heart", isPlaying: $isPlayingHeartAnimation)
                    .frame(width: 140, height: 140)
                    .scaleEffect(0.9)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isPlayingHeartAnimation = false
                        }
                    }
            }

            Button(action: {
                isPlayingHeartAnimation = true
                action()
            }) {
                Image("treasure")
                    .font(.system(size: 30))
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(50)
                    .shadow(radius: 10)
            }
        }
    }
}
