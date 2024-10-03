import SwiftUI
import AVFoundation

struct CustomAlert: View {
    @Binding var show: Bool
    @ObservedObject var audioRecorder: AudioRecorder
    @Binding var richText: NSAttributedString
    @Binding var isRecording: Bool
    @Binding var isPlaying: Bool
    @Binding var uploadedAudioURL: URL?

    var body: some View {
        ZStack {

            // 中央彈出視窗
            VStack(spacing: 25) {
                Text(isRecording ? "Recording..." : "Ready to Record")
                    .font(.headline)
                    .padding()

                if isRecording {
                    // 顯示停止按鈕
                    Button(action: {
                        audioRecorder.stopRecording()
                        isRecording = false
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.red)
                    }
                } else if let recordingURL = audioRecorder.recordingURL {
                    // 錄音停止後顯示播放、保存、刪除按鈕
                    Button(action: {
                        audioRecorder.playRecording(from: recordingURL)
                        isPlaying = true
                    }) {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        // 保存按鈕
                        Button(action: {
                               show = false // 保存後關閉
                                
                        }) {
                            Text("保存")
                                .foregroundColor(.green)
                                .padding()
                                .background(Capsule().stroke(Color.green, lineWidth: 2))
                        }

                        // 刪除按鈕
                        Button(action: {
                            try? FileManager.default.removeItem(at: recordingURL)
                            audioRecorder.recordingURL = nil
                            show = false // 刪除後關閉
                        }) {
                            Text("刪除")
                                .foregroundColor(.red)
                                .padding()
                                .background(Capsule().stroke(Color.red, lineWidth: 2))
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
                            .foregroundColor(.blue)
                    }
                }

                // 關閉按鈕（右上角）
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            show = false
                        }
                    }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
            }
            .padding(30)
            .background(BlurView())  // 添加模糊背景
            .cornerRadius(25)
            .shadow(radius: 10)
            .frame(width: 300, height: 300)  // 彈出視窗大小固定
        }
//        .animation(.easeInOut)
    }
}

// BlurView 用於背景模糊效果
struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
