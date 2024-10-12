import SwiftUI
import Kingfisher
import AVFoundation
import LinkPresentation

struct CollectionTreasureCardView: View {
    var treasure: Treasure
    @State private var audioPlayer: AVPlayer?
    @State private var isPlayingAudio = false
    @State private var showFullScreenImage = false
    @State private var selectedImageURL: URL?

    var body: some View {
        ZStack {
            if treasure.isPublic {
                // 正常顯示卡片內容
                VStack(alignment: .leading, spacing: 10) {
                    let hasMediaContent = treasure.contents.contains { $0.type == .image || $0.type == .video || $0.type == .link }

                    if hasMediaContent {
                        TabView {
                            ForEach(treasure.contents.sorted(by: { $0.index < $1.index })) { content in
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
                        .frame(height: 300)
                        .cornerRadius(8)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    }

                    if let audioContent = treasure.contents.first(where: { $0.type == .audio }) {
                        if let audioURL = URL(string: audioContent.content) {
                            AudioPlayerView(audioURL: audioURL)
                                .frame(height: 100)
                                .padding(.top, 10)
                                .padding(.bottom, 15)
                        }
                    }

                    if let textContent = treasure.contents.first(where: { $0.type == .text })?.content {
                        ScrollView {
                            Text(textContent)
                                .font(.custom("LexendDeca-Regular", size: 16))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5)
                                .lineSpacing(10.0)
                                .padding(.top, hasMediaContent ? 8 : 10)
                        }
                        .frame(maxHeight: 190)
                    }

                    Text("# \(treasure.category)")
                        .font(.custom("LexendDeca-SemiBold", size: 16))
                        .foregroundColor(.black)
                        .padding(.top, 10)

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
                .padding()
                .background(Color.white.opacity(0.6))
                .cornerRadius(15)
                .shadow(radius: 2)
            } else {
                // 顯示為私人寶藏的模糊背景卡片
                ZStack {
                    BlurView()
                        .frame(height: 100)
                        .cornerRadius(10)
                        .shadow(radius: 2)

                    Text("此寶藏已被設為私人")
                        .foregroundColor(.gray)
                        .font(.custom("LexendDeca-Regular", size: 16))
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 20)
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let imageURL = selectedImageURL {
                URLImageViewWithPreview(imageURL: imageURL)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
