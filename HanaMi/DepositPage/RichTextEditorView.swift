import SwiftUI
import UIKit

struct RichTextEditorView: UIViewRepresentable {
    @Binding var text: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        
        // 配置 TextKit 2 文本編輯器
        textView.isEditable = true
        textView.attributedText = text
        textView.delegate = context.coordinator
        
        // 基本設置
        textView.font = UIFont.systemFont(ofSize: 18)
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

    // 插入連結為區塊樣式（模擬連結預覽框）
    func insertLinkBlock(_ url: URL, displayText: String) {
        let mutableRichText = NSMutableAttributedString(attributedString: text)

        // 插入預覽區塊
        let linkAttachment = NSTextAttachment()
        linkAttachment.image = generateLinkPreview(url: url, text: displayText)
        
        // 設置連結預覽大小
        let targetWidth = UIScreen.main.bounds.width - 60
        let aspectRatio: CGFloat = 16/9 // 模擬視頻的寬高比
        let targetHeight = targetWidth / aspectRatio
        
        linkAttachment.bounds = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        let linkAttachmentString = NSAttributedString(attachment: linkAttachment)
        
        // 添加到富文本
        mutableRichText.append(linkAttachmentString)
        
        // 添加點擊事件
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .link: url
        ]
        let clickableText = NSAttributedString(string: "\n", attributes: linkAttributes) // 使預覽框成為可點擊區域
        mutableRichText.append(clickableText)
        
        text = mutableRichText
    }
    
    // 模擬生成連結預覽圖像（可以替換為真實預覽 API）
    func generateLinkPreview(url: URL, text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: UIScreen.main.bounds.width - 60, height: 150))
        return renderer.image { context in
            // 背景
            UIColor.systemGray6.setFill()
            context.fill(CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 60, height: 150))
            
            // 模擬插入 YouTube 預覽圖
            if let youtubeImage = UIImage(systemName: "play.rectangle.fill") {
                youtubeImage.draw(in: CGRect(x: 20, y: 20, width: 50, height: 50))
            }
            
            // 顯示連結文字
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.darkText
            ]
            let string = "\(text)\n\(url.absoluteString)"
            string.draw(with: CGRect(x: 80, y: 20, width: 220, height: 100), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        }
    }
    
    // 插入音訊
    func insertAudio() {
        let audioAttachment = NSTextAttachment()
        audioAttachment.image = UIImage(systemName: "speaker.wave.2.fill") // 代表音訊的圖標
        let audioString = NSAttributedString(attachment: audioAttachment)

        let mutableRichText = NSMutableAttributedString(attributedString: text)
        mutableRichText.append(audioString)
        text = mutableRichText
    }
}
