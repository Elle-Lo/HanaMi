import SwiftUI
import Kingfisher
import AVFoundation
import LinkPresentation

struct TreasureCardView: View {
    var treasure: Treasure
    @State private var audioPlayer: AVPlayer?
    @State private var isPlayingAudio = false
    @State private var showFullScreenImage = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 類別標籤
            
            
            // TabView 用於顯示圖片、影片、連結
            TabView {
                ForEach(treasure.contents.sorted(by: { $0.index < $1.index })) { content in
                    switch content.type {
                    case .image:
                        if let imageURL = URL(string: content.content) {
                            KFImage(imageURL)
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    selectedImage = UIImage(contentsOfFile: imageURL.path) // 這裡可以自定義全屏圖片處理
                                    showFullScreenImage = true
                                }
                        }
                    case .video:
                        if let videoURL = URL(string: content.content) {
                            VideoPlayerView(url: videoURL)
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
            .frame(height: 300) // 控制高度
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // 添加頁面指示器
            
            // 文字內容
            if let textContent = treasure.contents.first(where: { $0.type == .text })?.content {
                Text(textContent)
                    .font(.body)
                    .foregroundColor(.black)
                    .padding(.top, 10)
            }
            
            Text("# \(treasure.category)")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 10)
            
            // 經緯度顯示
            HStack(spacing: 4) {
                Image("pin")
                    .resizable()
                    .frame(width: 10, height: 10)
                Text("\(treasure.longitude), \(treasure.latitude)")
                    .font(.caption)
                    .foregroundColor(.black)
            }
            .padding(8)
//            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)
        }
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.6))
        .cornerRadius(15)
        .shadow(radius: 5)
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let selectedImage = selectedImage {
                ImageViewWithPreview(image: selectedImage)
            }
        }
    }
}
