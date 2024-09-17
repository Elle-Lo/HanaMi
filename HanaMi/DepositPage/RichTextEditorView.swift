import SwiftUI
import UIKit
import AVFoundation

struct RichTextEditorView: UIViewRepresentable {
    @Binding var text: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        // 配置 TextKit 文本编辑器
        textView.isEditable = true
        textView.attributedText = text
        textView.delegate = context.coordinator
        
        // 设置字体大小，调整链接显示大小
        textView.font = UIFont.systemFont(ofSize: 20) // 将字体大小设置为20
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditorView

        init(_ parent: RichTextEditorView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributedText
        }

        // 打開連結時的點擊行為
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            return true
        }
    }
    
    // 插入縮放後的圖片
    func insertImage(_ image: UIImage) {
        guard let textView = UITextView.appearance() as? UITextView else { return }
        let imageAttachment = NSTextAttachment()
        
        // 計算圖片尺寸，保持比例，寬度等於 TextView 的寬度
        let targetWidth = UIScreen.main.bounds.width - 60 // 保持與 TextView 相同的寬度（寬度調整為螢幕寬度 - padding）
        let aspectRatio = image.size.width / image.size.height
        let targetHeight = targetWidth / aspectRatio
        
        // 設置附件的大小
        imageAttachment.bounds = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        imageAttachment.image = image

        let imageString = NSAttributedString(attachment: imageAttachment)

        let mutableRichText = NSMutableAttributedString(attributedString: text)
        mutableRichText.append(imageString)
        text = mutableRichText
    }

    func insertLinkBlock(_ url: URL, displayText: String) {
        let linkString = NSMutableAttributedString(string: displayText, attributes: [
            .link: url,
            .foregroundColor: UIColor.blue, // 显示链接为蓝色
            .font: UIFont.systemFont(ofSize: 16) // 将链接文本设置为更大的字体（24号字体）
        ])
        
        let mutableRichText = NSMutableAttributedString(attributedString: text)
        mutableRichText.append(linkString)
        text = mutableRichText
    }
    
    // 检查麦克风权限并插入音频
    func insertAudio() {
        checkMicrophonePermission { granted in
            if granted {
                // 开始录音
                startRecording()
            } else {
                print("没有麦克风权限")
            }
        }
    }

        // 开始录音
        func startRecording() {
            // 此处为录音逻辑的简要示例，使用 AVAudioRecorder
            print("开始录音...")
            // 你可以进一步实现录音功能
        }
        
        // 跳转到 Apple Music
        func openAppleMusic() {
            if let appleMusicURL = URL(string: "https://music.apple.com") { // 替换为 Apple Music 链接
                UIApplication.shared.open(appleMusicURL, options: [:], completionHandler: nil)
            }
        }

    // 检查和请求麦克风权限（iOS 17+）
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            // 使用 AVAudioApplication 来检查麦克风权限
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                completion(true)
            case .denied:
                completion(false)
            case .undetermined:
                AVAudioApplication.requestRecordPermission { allowed in
                    DispatchQueue.main.async {
                        completion(allowed)
                    }
                }
            @unknown default:
                completion(false)
            }
        } else {
            // iOS 17 以下版本，仍然使用 AVAudioSession
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                completion(true)
            case .denied:
                completion(false)
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                    DispatchQueue.main.async {
                        completion(allowed)
                    }
                }
            @unknown default:
                completion(false)
            }
        }
    }

    }
