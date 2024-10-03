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

                    // 保存按鈕
                    if let recordingURL = audioRecorder.recordingURL {
                        Button(action: {
                            audioRecorder.uploadRecording { uploadedURL in
                                if let uploadedURL = uploadedURL {
                                    uploadedAudioURL = uploadedURL
                                    show = false // 保存後關閉
                                }
                            }
                        }) {
                            Text("保存")
                                .foregroundColor(.white)
                                .padding()
                                .background(Capsule().stroke(Color.green, lineWidth: 2))
                        }
                    }

                    // 刪除按鈕
                    if let recordingURL = audioRecorder.recordingURL {
                        Button(action: {
                            try? FileManager.default.removeItem(at: recordingURL)
                            audioRecorder.recordingURL = nil
                            show = false // 刪除後關閉
                        }) {
                            Text("刪除")
                                .foregroundColor(.white)
                                .padding()
                                .background(Capsule().stroke(Color.red, lineWidth: 2))
                        }
                    }
                }
                .padding(.horizontal, 20)

                // 關閉按鈕
                Button(action: {
                    withAnimation {
                        show = false
                    }
                }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(BlurView())  // 添加模糊背景
            .cornerRadius(25)
            .shadow(radius: 10)
            .frame(width: 300, height: 300)  // 彈出視窗大小
//            .transition(.scale)
        }
        .animation(.easeInOut)
    }
}
// BlurView 用於背景模糊效果
struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
