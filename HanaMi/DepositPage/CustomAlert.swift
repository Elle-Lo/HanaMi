import SwiftUI
import AVFoundation

struct CustomAlert: View {
    @Binding var show: Bool
    @Binding var richText: NSAttributedString
    @ObservedObject var audioRecorder: AudioRecorder
    @Binding var isRecording: Bool
    @Binding var isPlaying: Bool
    @Binding var uploadedAudioURL: URL?
    @State private var audioPlayer: AVPlayer?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDragging = false // 用於標記是否正在拖動進度條

    var body: some View {
        ZStack {
            // 中央彈出視窗
            VStack(spacing: 15) {
                // 關閉按鈕（右上角）
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            show = false
                        }
                    }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }

                // 錄音狀態顯示
                Text(isRecording ? "Recording..." : "Ready to Record")
                    .font(.custom("LexendDeca-SemiBold", size: 20))

                if isRecording {
                    // 顯示停止錄音按鈕
                    Button(action: {
                        audioRecorder.stopRecording()
                        isRecording = false
                        if let recordingURL = audioRecorder.recordingURL {
                            setupAudioPlayer(from: recordingURL)
                        }
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.red)
                    }
                } else if let recordingURL = audioRecorder.recordingURL {
                    // 錄音停止後顯示播放、保存、刪除按鈕
                    Button(action: {
                        togglePlayPause(for: recordingURL)
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.colorBrown)
                    }

                    // 播放進度條和時間顯示
                    HStack {
                        Text(formatTime(seconds: currentTime))  // 開始時間
                            .font(.caption)
                            .foregroundColor(.gray)

                        Slider(value: $currentTime, in: 0...duration, onEditingChanged: { editing in
                            isDragging = editing
                            if !editing {
                                audioPlayer?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
                            }
                        })
                        .accentColor(Color.gray)
                        .padding(.horizontal, 3)

                        Text(formatTime(seconds: duration))  // 結束時間
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 10)

                    HStack(spacing: 15) {
                        // 保存按鈕
                        Button(action: {
                            show = false // 保存後關閉
                        }) {
                            Text("保存")
                                .foregroundColor(.colorYellow)
                                .font(.custom("LexendDeca-SemiBold", size: 15))
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(.colorBrown)
                                .cornerRadius(15)
                        }

                        // 刪除按鈕
                        Button(action: {
                            deleteRecording(recordingURL)
                        }) {
                            Text("刪除")
                                .foregroundColor(.colorBrown)
                                .font(.custom("LexendDeca-SemiBold", size: 15))
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(.colorYellow)
                                .cornerRadius(15)
                        }
                    }
                } else {
                    // 顯示錄音按鈕
                    Button(action: {
                        audioRecorder.startRecording()
                        isRecording = true
                    }) {
                        Image(systemName: "mic.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.colorBrown)
                    }
                }
            }
            .padding(20)
            .background(BlurView())  // 添加模糊背景
            .cornerRadius(25)
            .shadow(radius: 10)
            .frame(width: 300, height: 400)
        }
        .onAppear {
            if let recordingURL = audioRecorder.recordingURL {
                setupAudioPlayer(from: recordingURL)
            }
        }
        .onDisappear {
            audioPlayer?.pause()
            isPlaying = false
        }
    }

    private func togglePlayPause(for url: URL) {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            setupAudioSession()  // 設置音頻會話
            audioPlayer?.play()
            isPlaying = true
        }
    }

    private func setupAudioPlayer(from url: URL) {
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.volume = 1.0
        if let currentItem = audioPlayer?.currentItem {
            duration = CMTimeGetSeconds(currentItem.asset.duration)
            
            // 監聽播放進度，定期更新進度條
            let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
            audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                if !isDragging {
                    currentTime = CMTimeGetSeconds(time)
                }
            }
        }
        
        // 當播放完畢後，重置狀態
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: audioPlayer?.currentItem, queue: .main) { _ in
            isPlaying = false
            currentTime = 0
            audioPlayer?.seek(to: CMTime(seconds: 0, preferredTimescale: 600))
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

    private func deleteRecording(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        audioRecorder.recordingURL = nil
        show = false // 刪除後關閉
    }

    private func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
