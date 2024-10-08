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
    @State private var selectedImageURL: URL? = nil
    private let firestoreService = FirestoreService()

    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }

    var body: some View {
        ZStack {
            Color(.colorYellow)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 顯示日期
                    Text(treasure.createdTime, formatter: dateFormatter)
                        .font(.custom("LexendDeca-SemiBold", size: 18))
                        .foregroundColor(.colorBrown)
                        .bold()

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
                                                .cornerRadius(10)
                                                .shadow(radius: 5)
                                                .padding(.vertical, 5)
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
                        ScrollView {
                            Text(textContent)
                                .font(.custom("LexendDeca-Regular", size: 16))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5)
                                .lineSpacing(10.0)
                                .padding(.top, mediaContents.isEmpty ? 0 : 10) // 如果沒有媒體，則不留間距
                        }
                    }

                    Spacer()
                }
            }
            .padding(.vertical, 50)
            .padding(.horizontal, 20)

            // 收藏按鈕，位於頁面底部中間
            VStack {
                Spacer()
                Button(action: {
                    addTreasureToFavorites()
                }) {
                    Image("treasure")
                        .font(.system(size: 30))
                        .foregroundColor(.colorBrown)
                        .padding()
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(50)
                        .shadow(radius: 10)
                }
                .padding(.bottom, 30)
            }
        }
    }

    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd (E)"
        return formatter
    }
    
    private func addTreasureToFavorites() {
        firestoreService.addTreasureToFavorites(userID: userID, treasureID: treasure.id ?? "") { result in
            switch result {
            case .success:
                alertMessage = "寶藏成功添加到收藏"
            case .failure(let error):
                alertMessage = "添加寶藏到收藏失敗：\(error.localizedDescription)"
            }
            showAlert = true
        }
    }
}
