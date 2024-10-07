import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer? = nil
    @State private var isPlaying: Bool = false
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
                            player.play()
                            isPlaying = true
                        }
                        .onDisappear {
                            player.pause()
                            isPlaying = false
                        }
                        .scaledToFill()  // 讓影片填滿範圍
                        .frame(width: 300, height: 300)  // 設置寬高一致
                        .cornerRadius(8)
                        .onTapGesture {
                            // 點擊影片縮略圖，進入全屏播放模式
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
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                        // 優先縮放手勢，再處理拖動手勢
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
                }

                // 右上角的關閉按鈕
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

    // 重置影片的位置和大小
    private func resetVideoPosition() {
        scale = 1.0
        dragOffset = .zero
        videoOffset = .zero
        lastScale = 1.0
    }
}
