import SwiftUI
import AVKit
import AVFoundation

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
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDragging = false // 用於標記是否正在拖動進度條

    var body: some View {
        ZStack {
            // 灰色邊框背景
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.colorYellow, lineWidth: 2) // 灰色邊框
                .background(Color.white.opacity(0.2)) // 背景顏色
                .cornerRadius(10) // 確保背景也有圓角
            
            VStack {
                // 播放按鈕
                Button(action: {
                    if isPlaying {
                        audioPlayer?.pause()
                        isPlaying = false
                    } else {
                        setupAudioSession()  // 確保在播放前設置音訊會話
                        playAudio()
                        isPlaying = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex:"FFF7EF")) // 背景顏色FFF7EF
                            .frame(width: 60, height: 60)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(hex:"522504")) // 按鈕顏色522504
                    }
                }
                
                // 播放進度條和時間顯示
                HStack {
                    // 開始時間
                    Text(formatTime(seconds: currentTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // 播放進度條
                    Slider(value: $currentTime, in: 0...duration, onEditingChanged: { editing in
                        isDragging = editing
                        if !editing {
                            audioPlayer?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
                        }
                    })
                    .accentColor(Color.gray)
                    .padding(.horizontal, 10)
                    
                    // 結束時間
                    Text(formatTime(seconds: duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
            }
            .padding()
        }
        .onAppear {
            prepareAudio()
        }
        .onDisappear {
            audioPlayer?.pause()
            isPlaying = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            // 播放完畢，重置按鈕狀態和進度
            isPlaying = false
            currentTime = 0
            audioPlayer?.seek(to: CMTime(seconds: 0, preferredTimescale: 600)) // 重置播放到頭部
        }
        .frame(maxWidth: .infinity, minHeight: 100) // 設置固定高度
    }

    private func playAudio() {
        audioPlayer?.play()
        isPlaying = true
    }

    private func prepareAudio() {
        audioPlayer = AVPlayer(url: audioURL)
        audioPlayer?.volume = 1.0 // 設置音量，避免音量默認為0
        if let currentItem = audioPlayer?.currentItem {
            duration = CMTimeGetSeconds(currentItem.asset.duration)
            
            // 監聽播放進度，定期更新進度條
            let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
            audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                if !isDragging { // 只有在不拖動進度條時才更新
                    currentTime = CMTimeGetSeconds(time)
                }
            }
        }
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    // 格式化時間為 mm:ss 的格式
    private func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
