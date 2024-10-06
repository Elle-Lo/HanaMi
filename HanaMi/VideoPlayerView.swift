import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer? = nil
    @State private var isPlaying: Bool = false
    @State private var showFullScreenPlayer: Bool = false  // 控制全屏播放的狀態
    @State private var dragOffset = CGSize.zero  // 控制下滑手勢

    var body: some View {
        VStack {
            if let player = player {
                ZStack(alignment: .center) {
                    VideoPlayer(player: player)
                        .onAppear {
                            player.play()
                            isPlaying = true
                        }
                        .onDisappear {
                            player.pause()
                            isPlaying = false
                        }
                        .frame(height: 200)
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
        .fullScreenCover(isPresented: $showFullScreenPlayer) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let player = player {
                    VideoPlayer(player: player)
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                        .edgesIgnoringSafeArea(.all)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.height > 0 {
                                        dragOffset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.height > 100 {
                                        showFullScreenPlayer = false
                                    }
                                    dragOffset = .zero
                                }
                        )
                        .offset(y: dragOffset.height)
                }
            
                // 添加一個關閉按鈕來退出全屏播放
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showFullScreenPlayer = false  // 關閉全屏播放
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
}
