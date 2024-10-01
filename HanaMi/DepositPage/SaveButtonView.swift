import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import MapKit

struct SaveButtonView: View {
    let userID: String
    let selectedCoordinate: CLLocationCoordinate2D?
    let selectedLocationName: String?
    let selectedCategory: String
    let isPublic: Bool
    let contents: NSAttributedString // 传递 NSAttributedString 而非处理后的内容
    @Binding var errorMessage: String?

    var firestoreService = FirestoreService()
    
    var onSave: () -> Void // 新增一個保存成功後的回調

    var body: some View {
            Button(action: {
                saveDataToFirestore()
            }) {
                Text("Save")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
    }

    // 保存地点和类别数据到 Firestore
    private func saveDataToFirestore() {
        guard let coordinate = selectedCoordinate, let locationName = selectedLocationName else {
            errorMessage = "請選擇一個有效的地點"
            return
        }

        if selectedCategory.isEmpty {
            errorMessage = "請選擇一個類別"
            return
        }

        // 提取富文本中的内容，检查是否有图片和音频
        extractContentsWithImageUpload(contents) { processedContents in
            // 将处理后的内容和其他信息一起存入 Firestore
            firestoreService.saveTreasure(userID: userID, coordinate: coordinate, locationName: locationName, category: selectedCategory, isPublic: isPublic, contents: processedContents) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success():
                        errorMessage = "數據保存成功"
                        onSave() // 保存成功後執行重置操作
                    case .failure(let error):
                        errorMessage = "保存數據失敗: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func extractContentsWithImageUpload(_ richText: NSAttributedString, completion: @escaping ([TreasureContent]) -> Void) {
        var contents: [TreasureContent] = []
        var pendingUploads = 0
        var currentIndex = 0

        // 遍历富文本内容
        richText.enumerateAttributes(in: NSRange(location: 0, length: richText.length), options: []) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? NSTextAttachment {
                // 检查是否是链接预览图
                if let link = attributes[.link] as? URL {
                    print("跳过预览图，不上传图片，只保存链接")
                    // 直接处理当前链接，不需要存入数组
                    let displayText = richText.attributedSubstring(from: range).string
                    let content = TreasureContent(type: .link, content: link.absoluteString, index: currentIndex, displayText: displayText)
                    contents.append(content)
                } else if let image = attachment.image {
                    // 用户插入的图片，进行上传
                    pendingUploads += 1
                    uploadMediaToStorage(imageData: image.pngData(), path: "images", type: .image, currentIndex: currentIndex) { content in
                        if let content = content {
                            contents.append(content)
                        }
                        pendingUploads -= 1
                        if pendingUploads == 0 {
                            completion(contents.sorted(by: { $0.index < $1.index }))
                        }
                    }
                }
            } else if let link = attributes[.link] as? URL {
                // 处理纯链接
                let displayText = richText.attributedSubstring(from: range).string
                let content = TreasureContent(type: .link, content: link.absoluteString, index: currentIndex, displayText: displayText)
                contents.append(content)
            } else {
                // 处理普通文本
                let text = richText.attributedSubstring(from: range).string
                let content = TreasureContent(type: .text, content: text, index: currentIndex)
                contents.append(content)
            }
            currentIndex += 1
        }

        // 如果没有文件需要上传，直接回调完成
        if pendingUploads == 0 {
            completion(contents.sorted(by: { $0.index < $1.index }))
        }
    }



    
    // 判斷是否是預覽附件（音頻或連結的預覽圖）
    private func isPreviewAttachment(_ attachment: NSTextAttachment) -> Bool {
        return attachment.accessibilityLabel == "LinkPreview" || attachment.accessibilityLabel == "AudioPreview"
    }


    private func uploadMediaToStorage(imageData: Data?, path: String, type: ContentType, currentIndex: Int, completion: @escaping (TreasureContent?) -> Void) {
        guard let data = imageData else {
            completion(nil)
            return
        }
        let storageRef = Storage.storage().reference().child("\(path)/\(UUID().uuidString).png") // 這裡可以根據需要改成其他副檔名
        storageRef.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                print("文件上传失败：\(error.localizedDescription)")
                completion(nil)
                return
            }
            storageRef.downloadURL { url, error in
                if let url = url {
                    let content = TreasureContent(type: type, content: url.absoluteString, index: currentIndex)
                    completion(content)
                } else {
                    print("获取下载URL失败: \(error?.localizedDescription ?? "未知错误")")
                    completion(nil)
                }
            }
        }
    }

}
