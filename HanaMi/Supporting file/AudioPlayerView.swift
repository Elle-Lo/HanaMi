import SwiftUI
import AVKit

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()  // 全局共享實例
    @Published var currentAudioPlayer: AVPlayer?
    @Published var isPlaying: Bool = false

    func playAudio(from url: URL) {
        stopCurrentAudio() // 先停止當前播放中的音頻
        currentAudioPlayer = AVPlayer(url: url)
        currentAudioPlayer?.play()
        isPlaying = true
    }

    func stopCurrentAudio() {
        currentAudioPlayer?.pause()
        isPlaying = false
    }
}

struct AudioPlayerView: View {
    let audioURL: URL
    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying = false
    @ObservedObject var audioPlayerManager = AudioPlayerManager.shared

    var body: some View {
        HStack {
            Button(action: {
                if audioPlayerManager.isPlaying {
                    audioPlayerManager.stopCurrentAudio()
                } else {
                    audioPlayerManager.playAudio(from: audioURL)
                }
            }) {
                Image(systemName: audioPlayerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
            }
        }
        .onDisappear {
                    audioPlayer?.pause() // 當視圖消失時停止播放
                    isPlaying = false
                }
    }
}
