import SwiftUI
import FirebaseFirestore
import Kingfisher
import AVKit

struct TreasureDetailView: View {
    let treasure: Treasure
    @State private var isPlayingAudio = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // 顯示標題和日期，將 Timestamp 轉換為 Date
                Text(treasure.createdTime, formatter: dateFormatter)
                    .font(.title2)
                    .bold()

                // 公開狀態、類別和地點
                HStack(spacing: 8) {
                    Text(treasure.isPublic ? "公開" : "私人")
                        .padding(8)
                        .background(treasure.isPublic ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                        .cornerRadius(10)
                    
                    Text(treasure.category)
                        .padding(8)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)

                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(treasure.locationName)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                }
                .font(.subheadline)
                .padding(.bottom, 10)

                // 文字內容
                // 顯示文字內容
                ForEach(treasure.contents.filter { $0.type == .text }, id: \.id) { content in
                    Text(content.content)
                        .font(.body)
                        .lineSpacing(5)
                        .padding(.vertical, 10) // 與圖片的垂直間距保持一致
                }

                // 圖片顯示
                ForEach(treasure.contents.filter { $0.type == .image }, id: \.id) { content in
                    if let url = URL(string: content.content) {
                        KFImage(url)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.vertical, 10)
                    }
                }

                // 音頻內容
                ForEach(treasure.contents.filter { $0.type == .audio }, id: \.id) { content in
                    if let audioURL = URL(string: content.content) {
                        AudioPlayerView(audioURL: audioURL)
                            .padding(.vertical, 10)
                    }
                }

                // 影片顯示 (可使用AVPlayer)
                ForEach(treasure.contents.filter { $0.type == .video }, id: \.id) { content in
                    if let videoURL = URL(string: content.content) {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(height: 250)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.vertical, 10)
                    }
                }

                // 連結顯示
                ForEach(treasure.contents.filter { $0.type == .link }, id: \.id) { content in
                    if let url = URL(string: content.content) {
                        LinkPreviewView(url: url)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.vertical, 10)
                    }
                }
            }
            .padding()
        }
    }
    
    // 日期格式
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd (E)"
        return formatter
    }
}
