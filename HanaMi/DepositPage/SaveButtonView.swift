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
                        onSave() // 保存成功後執行重置操作
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
        var pendingUploads = 0 // 跟踪待上传文件的数量
        var currentIndex = 0   // 用来记录每个内容的顺序
        
        // 遍历富文本，处理文本、图片和音频
        richText.enumerateAttributes(in: NSRange(location: 0, length: richText.length), options: []) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? NSTextAttachment, let image = attachment.image {
                // 处理图片上传
                pendingUploads += 1
                uploadImageToStorage(image) { result in
                    switch result {
                    case .success(let url):
                        let content = TreasureContent(type: .image, content: url.absoluteString, index: currentIndex)
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
                let content = TreasureContent(type: .link, content: link.absoluteString, index: currentIndex, displayText: displayText)
                contents.append(content)
            } else if let audioURL = attributes[.link] as? URL, audioURL.pathExtension == "m4a" {
                // 处理音频上传
                pendingUploads += 1
                uploadAudioToStorage(audioURL) { result in
                    switch result {
                    case .success(let url):
                        let content = TreasureContent(type: .audio, content: url.absoluteString, index: currentIndex)
                        contents.append(content)
                    case .failure(let error):
                        print("音频上传失败：\(error.localizedDescription)")
                    }
                    pendingUploads -= 1
                    if pendingUploads == 0 {
                        completion(contents)
                    }
                }
            } else {
                // 处理普通文本
                let text = richText.attributedSubstring(from: range).string
                let content = TreasureContent(type: .text, content: text, index: currentIndex)
                contents.append(content)
            }
            currentIndex += 1 // 递增索引
        }
        
        // 如果没有文件上传，直接回调完成
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

    // 上传音频到 Firebase Storage
    private func uploadAudioToStorage(_ audioURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("audios/\(UUID().uuidString).m4a")
        
        do {
            let audioData = try Data(contentsOf: audioURL)
            storageRef.putData(audioData, metadata: nil) { metadata, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // 获取音频下载URL
                storageRef.downloadURL { url, error in
                    if let url = url {
                        completion(.success(url))
                    } else {
                        completion(.failure(error!))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}
