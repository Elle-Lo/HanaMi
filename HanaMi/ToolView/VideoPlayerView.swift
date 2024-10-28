import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var showFullScreenPlayer: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var videoOffset: CGSize = .zero

    var body: some View {
        VStack {
            if let player = player {
                ZStack(alignment: .center) {
                    VideoPlayer(player: player)
                        .onAppear {
                            setupAudioSession()
                            player.seek(to: .zero)
                        }
                        .scaledToFill()
                        .cornerRadius(8)
                        .onTapGesture {
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
        .fullScreenCover(isPresented: $showFullScreenPlayer, onDismiss: {
            resetVideoPosition()
            player?.pause()
        }) {
            fullScreenVideoView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            player?.seek(to: .zero)
        }
    }
    
    private func fullScreenVideoView() -> some View {
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
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    videoOffset.width += value.translation.width
                                    videoOffset.height += value.translation.height
                                    dragOffset = .zero

                                    if value.translation.height > 200 {
                                        showFullScreenPlayer = false
                                    }
                                }
                            )
                    )
                    .onAppear {
                        player.play()
                    }
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showFullScreenPlayer = false
                            player.pause()
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

    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
            try audioSession.setActive(true)
            print("Audio session activated for playback.")
        } catch {
            print("Failed to activate audio session: \(error.localizedDescription)")
        }
    }

    private func resetVideoPosition() {
        scale = 1.0
        dragOffset = .zero
        videoOffset = .zero
        lastScale = 1.0
    }
}
