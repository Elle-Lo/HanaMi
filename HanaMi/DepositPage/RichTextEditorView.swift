import SwiftUI
import UIKit
import AVKit
import AVFoundation
import FirebaseStorage
import LinkPresentation

struct RichTextEditorView: UIViewRepresentable {
    @Binding var text: NSAttributedString
    @State private var lastInsertedAudioURL: URL? // 保存最新插入的音頻 URL
    @State private var videoLink: URL? // 用於存儲影片連結
    @State private var lastInsertedLinkURL: URL?
    var onVideoTapped: (URL) -> Void // 回调函数，点击视频时触发

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        
        // 配置 TextKit 文本编辑器
        textView.isEditable = true
        textView.attributedText = text
        textView.delegate = context.coordinator

        // 设置字体大小，调整链接显示大小
        textView.font = UIFont.systemFont(ofSize: 20) // 设置字体大小为 20
        
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

        // 处理文本改变
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributedText
            
            // 檢查音頻連結是否被刪除，若是則刪除 Firebase Storage 中的音頻
            if let audioURL = parent.lastInsertedAudioURL, !(textView.text as NSString).contains(audioURL.absoluteString) {
                deleteAudioFromStorage(audioURL)
            }
        }

        // 打開連結的點擊行為
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            parent.onVideoTapped(URL)
            return false // 阻止 UITextView 的默認行為
        }

        // 刪除 Firebase Storage 中的音頻
        func deleteAudioFromStorage(_ audioURL: URL) {
            let storageRef = Storage.storage().reference(forURL: audioURL.absoluteString)
            storageRef.delete { error in
                if let error = error {
                    print("無法刪除音頻：\(error.localizedDescription)")
                } else {
                    print("音頻已成功刪除")
                }
            }
        }
    }
    
    // 插入圖片到富文本編輯器
    func insertImage(_ image: UIImage) {
        let imageAttachment = NSTextAttachment()

        // 计算图片尺寸，保持比例
        let targetWidth = UIScreen.main.bounds.width - 80
        let aspectRatio = image.size.width / image.size.height
        let targetHeight = targetWidth / aspectRatio
        
        // 设置附件大小
        imageAttachment.bounds = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        imageAttachment.image = image

        let imageString = NSAttributedString(attachment: imageAttachment)

        let mutableRichText = NSMutableAttributedString(attributedString: text)
        mutableRichText.append(imageString)
        text = mutableRichText
    }
    
    func insertVideoPreview(from url: URL) {
           let asset = AVAsset(url: url)
           let assetImageGenerator = AVAssetImageGenerator(asset: asset)
           assetImageGenerator.appliesPreferredTrackTransform = true

           var time = asset.duration
           time.value = min(time.value, 2)  // 獲取影片的第二秒作為縮圖

           if let cgImage = try? assetImageGenerator.copyCGImage(at: time, actualTime: nil) {
               let thumbnail = UIImage(cgImage: cgImage)
               
               // 設定縮圖大小
               let maxWidth: CGFloat = 200
               let aspectRatio = thumbnail.size.width / thumbnail.size.height
               let targetHeight = maxWidth / aspectRatio

               let attachment = NSTextAttachment()
               attachment.image = thumbnail
               attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: targetHeight)

               // 創建包含影片縮圖的富文本
               let attributedString = NSMutableAttributedString(attachment: attachment)
               
               // 添加影片的 URL，當點擊時使用
               attributedString.addAttribute(.link, value: url, range: NSRange(location: 0, length: attributedString.length))
               
               // 將影片縮圖插入到富文本編輯器
               let mutableRichText = NSMutableAttributedString(attributedString: text)
               mutableRichText.append(attributedString)
               text = mutableRichText
               videoLink = url
           }
       }

    func insertLinkPreview(url: URL) {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            if let metadata = metadata {
                DispatchQueue.main.async {
                    let linkView = LPLinkView(metadata: metadata)
                    linkView.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 60, height: 0)
                    linkView.sizeToFit()
                    let image = linkView.snapshot()

                    // 插入预览图到富文本编辑器
                    self.insertImageWithLink(image: image, url: url)

                    // 不再保存到数组，直接处理当前链接
                }
            } else {
                // 如果无法获取元数据，插入普通链接文本
                DispatchQueue.main.async {
                    self.insertPlainLink(url: url)
                    // 不再保存到数组，直接处理当前链接
                }
            }
        }
    }



    func insertImageWithLink(image: UIImage, url: URL) {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image

        // 計算圖片顯示寬度，讓它保持距離螢幕邊框一點距離
        let maxWidth = UIScreen.main.bounds.width - 40 // 留出適當的邊距
        let aspectRatio = image.size.width / image.size.height

        // 確保寬度為 maxWidth，高度根據寬高比計算
        let targetWidth = maxWidth
        let targetHeight = targetWidth / aspectRatio

        // 設置 NSTextAttachment 的 bounds 來調整圖片顯示的大小，確保比例不變
        imageAttachment.bounds = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)

        // 創建帶有附件的 NSAttributedString
        let imageString = NSAttributedString(attachment: imageAttachment)

        // 添加自定義屬性來標記這是連結預覽圖
        let mutableImageString = NSMutableAttributedString(attributedString: imageString)
        mutableImageString.addAttribute(.link, value: url, range: NSRange(location: 0, length: mutableImageString.length))
        mutableImageString.addAttribute(NSAttributedString.Key("isLinkPreview"), value: true, range: NSRange(location: 0, length: mutableImageString.length))

        // 將圖片插入到富文本中
        let mutableRichText = NSMutableAttributedString(attributedString: text)
        mutableRichText.append(mutableImageString)
        text = mutableRichText
    }

        // 插入普通链接文本
        func insertPlainLink(url: URL) {
            let linkString = NSMutableAttributedString(string: url.absoluteString, attributes: [
                .link: url,
                .foregroundColor: UIColor.blue,
                .font: UIFont.systemFont(ofSize: 16)
            ])

            let mutableRichText = NSMutableAttributedString(attributedString: text)
            mutableRichText.append(linkString)
            text = mutableRichText

            lastInsertedLinkURL = url
        }
    
    // 插入音频链接并在末尾添加空格
    func insertAudioLink(_ url: URL) {
        let audioLink = NSMutableAttributedString(string: " [錄音檔: \(url.lastPathComponent)] ")
        audioLink.addAttribute(.link, value: url, range: NSRange(location: 0, length: audioLink.length))
        audioLink.addAttribute(.backgroundColor, value: UIColor.systemGray5, range: NSRange(location: 0, length: audioLink.length))
        audioLink.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: audioLink.length))
        
        // 添加一個空格，避免連結後的文字也成為連結的一部分
        let spaceString = NSAttributedString(string: " ", attributes: [
            .font: UIFont.systemFont(ofSize: 16), // 保持与連結相同的字體大小
            .foregroundColor: UIColor.black // 確保空白字符不會被連結樣式影響
        ])

        let mutableRichText = NSMutableAttributedString(attributedString: text)
        mutableRichText.append(audioLink)
        mutableRichText.append(spaceString) // 在連結後添加空格
        
        text = mutableRichText
        
        // 保存最新的音頻 URL
        lastInsertedAudioURL = url
    }
    
    // 请求麦克风权限并开始录音
    func insertAudio() {
        checkMicrophonePermission { granted in
            if granted {
                startRecording()
            } else {
                print("没有麦克风权限")
            }
        }
    }

    func startRecording() {
        // 实现你的录音逻辑
        print("开始录音...")
    }

    // 检查和请求麦克风权限
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
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
