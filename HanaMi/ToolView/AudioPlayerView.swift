import SwiftUI
import AVKit

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()  // 全局共享實例
    @Published var currentAudioPlayer: AVPlayer?
    @Published var isPlaying: Bool = false

    func playAudio(from url: URL) {
        stopCurrentAudio() 
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
                    if isPlaying {
                        audioPlayer?.pause()
                        isPlaying = false
                    } else {
                        setupAudioSession()
                        playAudio()
                        isPlaying = true
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                }
            }
            .onDisappear {
                audioPlayer?.pause()
                isPlaying = false
            }
        }

        private func playAudio() {
            audioPlayer = AVPlayer(url: audioURL)
            audioPlayer?.play()
        }

        // 設置音訊會話的函數
        private func setupAudioSession() {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playback, mode: .default, options: [])
                try audioSession.setActive(true)
            } catch {
                print("Failed to set up audio session: \(error.localizedDescription)")
            }
        }
    }
