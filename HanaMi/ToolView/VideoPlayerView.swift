import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer? = nil
    @State private var showFullScreenPlayer: Bool = false  // 控制全屏播放的狀態
    @State private var dragOffset: CGSize = .zero  // 控制拖動手勢
    @State private var scale: CGFloat = 1.0  // 縮放比例
    @State private var lastScale: CGFloat = 1.0  // 上次的縮放比例
    @State private var videoOffset: CGSize = .zero  // 記錄影片相對於初始位置的偏移量

    var body: some View {
        VStack {
            if let player = player {
                ZStack(alignment: .center) {
                    // ScrollView 中的影片縮略圖
                    VideoPlayer(player: player)
                        .onAppear {
                            player.seek(to: .zero)  // 初始化時將影片設置到最開始
                        }
                        .scaledToFill()  // 讓影片填滿範圍
                        .frame(width: 300, height: 300)  // 設置寬高一致
                        .cornerRadius(8)
                        .onTapGesture {
                            // 點擊影片進入全屏播放模式
                            showFullScreenPlayer = true
                        }
                }
            } else {
                Text("Loading video...")
                    .onAppear {
                        self.player = AVPlayer(url: url)
                    }
            }
        }
        // 全屏播放視圖
        .fullScreenCover(isPresented: $showFullScreenPlayer, onDismiss: {
            resetVideoPosition()  // 重置影片位置和縮放
        }) {
            ZStack {
                Color.black.ignoresSafeArea()

                if let player = player {
                    VideoPlayer(player: player)
                        .scaleEffect(scale)
                        .offset(x: dragOffset.width + videoOffset.width, y: dragOffset.height + videoOffset.height)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale *= delta
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                                .simultaneously(with: DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation  // 跟踪當前手勢的偏移量
                                    }
                                    .onEnded { value in
                                        videoOffset.width += value.translation.width
                                        videoOffset.height += value.translation.height
                                        dragOffset = .zero

                                        // 如果拖動超過一定高度，關閉全屏
                                        if value.translation.height > 200 {
                                            showFullScreenPlayer = false
                                        }
                                    }
                                )
                        )
                        .edgesIgnoringSafeArea(.all)

                    // 全屏模式的右上角關閉按鈕
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                showFullScreenPlayer = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            // 影片播放完畢，重置影片至開頭
            player?.seek(to: .zero)
        }
    }

    // 重置影片的位置和大小
    private func resetVideoPosition() {
        scale = 1.0
        dragOffset = .zero
        videoOffset = .zero
        lastScale = 1.0
    }
}
