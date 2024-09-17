import SwiftUI
import AVFoundation

struct AudioRecorderView: View {
    @ObservedObject var audioRecorder: AudioRecorder
    @Binding var showingAudioPicker: Bool // 控制視圖顯示
    var onRecordingComplete: (URL?) -> Void // 錄音完成後的回調

    var body: some View {
        VStack(spacing: 20) {
            if audioRecorder.audioRecorder == nil {
                // 開始錄音按鈕
                Button(action: {
                    audioRecorder.startRecording()
                }) {
                    Text("開始錄音")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }
            } else {
                // 停止錄音按鈕
                Button(action: {
                    audioRecorder.stopRecording()
                    onRecordingComplete(audioRecorder.getAudioFilePath()) // 回傳錄音檔案的 URL
                    showingAudioPicker = false // 關閉音頻選擇器
                }) {
                    Text("停止錄音")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }

            // 顯示當前錄音檔案的URL
            if let url = audioRecorder.getAudioFilePath() {
                Text("錄音文件: \(url.lastPathComponent)")
                    .font(.caption)
            }
        }
        .padding()
    }
}
