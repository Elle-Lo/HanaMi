import SwiftUI
import AVFoundation

struct RecordingSheet: View {
    @ObservedObject var audioRecorder: AudioRecorder
    @Binding var richText: NSAttributedString
    @Binding var isRecording: Bool // 控制錄音狀態
    @Binding var isPlaying: Bool // 控制播放狀態
    @Binding var uploadedAudioURL: URL? // 上傳後的 URL
    @Environment(\.dismiss) var dismiss // 用於關閉 sheet

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(isRecording ? "錄音中..." : isPlaying ? "播放中..." : "已停止錄音")
                    .font(.headline)
                    .padding()
                Spacer()
            }

            // 動態音條顯示（僅在錄音時顯示）
            if isRecording {
                HStack(spacing: 4) {
                    ForEach(0..<10, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: 5, height: .random(in: 10...60)) // 動態高度
                            .foregroundColor(.red)
                            .animation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true), value: isRecording)
                    }
                }
            }

            HStack {
                // 錄音按鈕
                Button(action: {
                    if audioRecorder.audioRecorder == nil {
                        audioRecorder.startRecording()
                        isRecording = true
                    } else {
                        audioRecorder.stopRecording()
                        isRecording = false
                    }
                }) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(isRecording ? .red : .blue)
                }

                Spacer()

                // 播放錄音按鈕
                if let recordingURL = audioRecorder.recordingURL {
                    Button(action: {
                        audioRecorder.playRecording(from: recordingURL)
                        isPlaying = true
                    }) {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)
                    }
                }

                // 保存按鈕
                if let recordingURL = audioRecorder.recordingURL {
                    Button(action: {
                        audioRecorder.uploadRecording { uploadedURL in
                            if let uploadedURL = uploadedURL {
                                uploadedAudioURL = uploadedURL
                                insertAudioLink(uploadedURL)
                                dismiss() // 保存後關閉 sheet
                            }
                        }
                    }) {
                        Text("保存")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }

                // 刪除按鈕
                if let recordingURL = audioRecorder.recordingURL {
                    Button(action: {
                        try? FileManager.default.removeItem(at: recordingURL)
                        audioRecorder.recordingURL = nil
                        dismiss() // 刪除後關閉 sheet
                    }) {
                        Text("刪除")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .frame(height: 200) // 設置較小的 sheet 高度
        .padding()
    }

    // 插入音頻連結到富文本，包在一個矩形內
    func insertAudioLink(_ url: URL) {
        // 包裝在矩形內的連結樣式
        let audioLink = NSMutableAttributedString(string: " [錄音檔: \(url.lastPathComponent)] ")
        audioLink.addAttribute(.link, value: url, range: NSRange(location: 0, length: audioLink.length))
        audioLink.addAttribute(.backgroundColor, value: UIColor.systemGray5, range: NSRange(location: 0, length: audioLink.length)) // 添加背景色

        let mutableRichText = NSMutableAttributedString(attributedString: richText)
        mutableRichText.append(audioLink)

        // 更新富文本
        richText = mutableRichText
    }
}
