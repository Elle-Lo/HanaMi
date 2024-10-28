import SwiftUI
import AVKit
import AVFoundation

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()
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
    @State private var isDragging = false

    var body: some View {
        ZStack {
          
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.colorYellow, lineWidth: 2)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            
            VStack {
               
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
                    ZStack {
                        Circle()
                            .fill(Color(hex:"FFF7EF"))
                            .frame(width: 60, height: 60)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(hex:"522504"))
                    }
                }
                
                HStack {
                
                    Text(formatTime(seconds: currentTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Slider(value: $currentTime, in: 0...duration, onEditingChanged: { editing in
                        isDragging = editing
                        if !editing {
                            audioPlayer?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
                        }
                    })
                    .accentColor(Color.gray)
                    .padding(.horizontal, 10)
                    
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
         
            isPlaying = false
            currentTime = 0
            audioPlayer?.seek(to: CMTime(seconds: 0, preferredTimescale: 600))
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }

    private func playAudio() {
        audioPlayer?.play()
        isPlaying = true
    }

    private func prepareAudio() {
        audioPlayer = AVPlayer(url: audioURL)
        audioPlayer?.volume = 1.0
        if let currentItem = audioPlayer?.currentItem {
            duration = CMTimeGetSeconds(currentItem.asset.duration)
            
            let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
            audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                if !isDragging {
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

    private func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
