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

    var body: some View {
        HStack {
            Spacer()
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
            Spacer()
        }
        .padding(.bottom, 30)
    }

    // 保存地點和類別數據到 Firestore
    private func saveDataToFirestore() {
        guard let coordinate = selectedCoordinate, let locationName = selectedLocationName else {
            errorMessage = "請選擇一個有效的地點"
            return
        }

        if selectedCategory.isEmpty {
            errorMessage = "請選擇一個類別"
            return
        }

        // Step 1: 提取富文本中的内容，检查是否有图片
        extractContentsWithImageUpload(contents) { processedContents in
            // Step 2: 将处理后的内容和其他信息一起存入 Firestore
            firestoreService.saveTreasure(userID: userID, coordinate: coordinate, locationName: locationName, category: selectedCategory, isPublic: isPublic, contents: processedContents) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success():
                        errorMessage = "數據保存成功"
                    case .failure(let error):
                        errorMessage = "保存數據失敗: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    // 提取富文本内容并处理图片上传
    private func extractContentsWithImageUpload(_ richText: NSAttributedString, completion: @escaping ([TreasureContent]) -> Void) {
        var contents: [TreasureContent] = []
        var pendingUploads = 0 // 跟踪待上传图片的数量
        
        // 遍历富文本，处理文本和图片
        richText.enumerateAttributes(in: NSRange(location: 0, length: richText.length), options: []) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? NSTextAttachment, let image = attachment.image {
                // 检测到图片附件，上传图片到 Firebase Storage
                pendingUploads += 1
                uploadImageToStorage(image) { result in
                    switch result {
                    case .success(let url):
                        // 上传成功，使用图片的 URL 替换图片内容
                        let content = TreasureContent(type: .image, content: url.absoluteString)
                        contents.append(content)
                    case .failure(let error):
                        print("图片上传失败：\(error.localizedDescription)")
                    }
                    pendingUploads -= 1
                    if pendingUploads == 0 {
                        completion(contents)
                    }
                }
            } else if let link = attributes[.link] as? URL {
                // 处理链接
                let displayText = richText.attributedSubstring(from: range).string
                let content = TreasureContent(type: .link, content: link.absoluteString, displayText: displayText)
                contents.append(content)
            } else {
                // 处理普通文本
                let text = richText.attributedSubstring(from: range).string
                let content = TreasureContent(type: .text, content: text)
                contents.append(content)
            }
        }
        
        // 如果没有图片上传，直接回调完成
        if pendingUploads == 0 {
            completion(contents)
        }
    }

    // 上传图片到 Firebase Storage
    private func uploadImageToStorage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("images/\(UUID().uuidString).png")
        if let imageData = image.pngData() {
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // 获取图片下载URL
                storageRef.downloadURL { url, error in
                    if let url = url {
                        completion(.success(url))
                    } else {
                        completion(.failure(error!))
                    }
                }
            }
        } else {
            completion(.failure(NSError(domain: "image-upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法转换图片数据"])))
        }
    }
}
