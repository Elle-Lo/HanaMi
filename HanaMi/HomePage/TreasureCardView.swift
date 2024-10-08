import SwiftUI
import Kingfisher
import AVFoundation
import LinkPresentation

struct TreasureCardView: View {
    var treasure: Treasure
    @State private var audioPlayer: AVPlayer?
    @State private var isPlayingAudio = false
    @State private var showFullScreenImage = false
    @State private var selectedImageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // 檢查是否有圖片、影片或連結的內容
            let hasMediaContent = treasure.contents.contains { $0.type == .image || $0.type == .video || $0.type == .link }
            
            if hasMediaContent {
                // TabView 用於顯示圖片、影片、連結
                TabView {
                    ForEach(treasure.contents.sorted(by: { $0.index < $1.index })) { content in
                        switch content.type {
                        case .image:
                            if let imageURL = URL(string: content.content) {
                                URLImageViewWithPreview(imageURL: imageURL) // 直接使用 URLImageViewWithPreview
                            }
                            
                        case .video:
                            if let videoURL = URL(string: content.content) {
                                VideoPlayerView(url: videoURL)
                                    .scaledToFill()  // 影片填滿框架
                                    .frame(width: 350, height: 300)
                                    .cornerRadius(8)
                                    .clipped()  // 剪裁溢出的部分
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
                .frame(height: 300)
                .cornerRadius(8)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: treasure.contents.count > 1 ? .always : .never)) // 這裡動態顯示或隱藏頁面指示器
            }
            
            // 音訊內容單獨處理，設置固定高度
            if let audioContent = treasure.contents.first(where: { $0.type == .audio }) {
                if let audioURL = URL(string: audioContent.content) {
                    AudioPlayerView(audioURL: audioURL)
                        .frame(height: 100)
                        .padding(.top, 10)
                        .padding(.bottom, 15)
                }
            }
            
            // 文字內容的 ScrollView，當文字內容過多時可以滾動
            if let textContent = treasure.contents.first(where: { $0.type == .text })?.content {
                ScrollView {
                    Text(textContent)
                        .font(.custom("LexendDeca-Regular", size: 16))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .lineSpacing(10.0)
                        .padding(.top, hasMediaContent ? 8 : 10)
                }
                .frame(maxHeight: 300)
            }
            
            // 類別標籤
            Text("# \(treasure.category)")
                .font(.custom("LexendDeca-SemiBold", size: 16))
                .foregroundColor(.black)
                .padding(.top, 10)
            
            // 經緯度顯示
            HStack(spacing: 4) {
                Image("pin")
                    .resizable()
                    .frame(width: 13, height: 13)
                Text("\(treasure.longitude), \(treasure.latitude)")
                    .font(.custom("LexendDeca-SemiBold", size: 12))
                    .foregroundColor(.colorBrown)
            }
            .cornerRadius(15)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.6))
        .cornerRadius(15)
        .shadow(radius: 5)
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let imageURL = selectedImageURL {
                URLImageViewWithPreview(imageURL: imageURL)  // 使用URL來進行圖片預覽
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
