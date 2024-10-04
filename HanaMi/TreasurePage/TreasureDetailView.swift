import SwiftUI
import FirebaseFirestore
import Kingfisher
import AVKit

struct TreasureDetailView: View {
    let treasure: Treasure
    @State private var isPlayingAudio = false
    @State private var showAlert = false
    @State private var alertMessage = ""
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
                        .font(.title3)
                        .foregroundColor(.colorBrown)
                        .bold()

                    // 公開狀態、類別和地點
                    HStack(spacing: 8) {
                        if treasure.isPublic {
                            Text("公開")
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .font(.system(size: 15))
                                .background(Color.colorYellow)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.colorBrown, lineWidth: 2) // 邊框顏色
                                )
                                .foregroundColor(.colorBrown) // 字體顏色
                                .bold()
                        } else {
                            Text("私人")
                                .padding(.vertical, 10)
                                .padding(.horizontal, 15)
                                .font(.system(size: 15))
                                .background(Color.colorBrown)
                                .cornerRadius(10)
                                .foregroundColor(.colorYellow) // 字體顏色
                                .bold()
                        }
                        
                        Text(treasure.category)
                            .padding(10)
                            .background(Color(hex: "D4D4D4").opacity(0.9)) // 類別標籤背景
                            .cornerRadius(10)
                            .foregroundColor(.colorYellow) // 字體顏色
                            .bold()
                        
                    }
                    .font(.subheadline)
                    .padding(.leading, 2)

                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.colorBrown) // 圖標顏色
                        Text(treasure.locationName)
                            .foregroundColor(.colorBrown) // 字體顏色
                            .font(.system(size: 15))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Color(hex: "E8E8E8").opacity(0.75)) // 地標背景
                    .cornerRadius(10)
                    .bold()
                    
                    // 圖片、影片和音訊的 Horizontal ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // 圖片顯示
                            ForEach(treasure.contents.filter { $0.type == .image }, id: \.id) { content in
                                if let url = URL(string: content.content) {
                                    KFImage(url)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .cornerRadius(10)
                                        .shadow(radius: 2)
                                }
                            }

                            // 影片顯示
                            ForEach(treasure.contents.filter { $0.type == .video }, id: \.id) { content in
                                if let videoURL = URL(string: content.content) {
                                    VideoPlayer(player: AVPlayer(url: videoURL))
                                        .frame(width: 250, height: 200)
                                        .cornerRadius(10)
                                        .shadow(radius: 2)
                                }
                            }

                            // 音頻顯示
                            ForEach(treasure.contents.filter { $0.type == .audio }, id: \.id) { content in
                                if let audioURL = URL(string: content.content) {
                                    AudioPlayerView(audioURL: audioURL)
                                        .frame(width: 200, height: 200)  // 設定大小來符合 ScrollView
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .shadow(radius: 2)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)

                    // 文字內容
                    ForEach(treasure.contents.filter { $0.type == .text }, id: \.id) { content in
                        Text(content.content)
                            .font(.body)
                            .lineSpacing(5)
                            .padding(.horizontal)
                            .padding(.vertical, 10) // 與圖片的垂直間距保持一致
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
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(50)
                        .shadow(radius: 10) // 添加陰影效果
                }
                .padding(.bottom, 30) // 使按鈕與頁面底部保持距離
            }
        }
    }

    // 日期格式
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
