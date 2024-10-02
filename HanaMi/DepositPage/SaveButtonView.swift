import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import MapKit
import UniformTypeIdentifiers

struct SaveButtonView: View {
    let userID: String
    let selectedCoordinate: CLLocationCoordinate2D?
    let selectedLocationName: String?
    let selectedCategory: String
    let isPublic: Bool
    let contents: NSAttributedString
    @Binding var errorMessage: String?

    var firestoreService = FirestoreService()
    var onSave: () -> Void

    var body: some View {
        Button(action: {
            saveDataToFirestore()
        }) {
            Text("Save")
                .font(.system(size: 16))
                .foregroundColor(.colorBrown)
                .padding()
                .background(Color.colorYellow)
                .cornerRadius(10)
        }
    }

    private func saveDataToFirestore() {
        guard let coordinate = selectedCoordinate,
              let locationName = selectedLocationName else {
            errorMessage = "請選擇一個有效的地點"
            return
        }

        if selectedCategory.isEmpty {
            errorMessage = "請選擇一個類別"
            return
        }

        extractContentsWithMediaUpload(contents) { processedContents in
            firestoreService.saveTreasure(
                userID: userID,
                coordinate: coordinate,
                locationName: locationName,
                category: selectedCategory,
                isPublic: isPublic,
                contents: processedContents
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success():
                        errorMessage = "數據保存成功"
                        onSave()
                    case .failure(let error):
                        errorMessage = "保存數據失敗: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func extractContentsWithMediaUpload(_ richText: NSAttributedString, completion: @escaping ([TreasureContent]) -> Void) {
        var contents: [TreasureContent] = []
        var pendingUploads = 0
        var currentIndex = 0

        let fullRange = NSRange(location: 0, length: richText.length)

        richText.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? NSTextAttachment {
                currentIndex += 1

                if let fileType = attachment.fileType {
                    if fileType == UTType.movie.identifier {
                        // 处理视频附件
                        pendingUploads += 1
                        if let videoURL = attributes[.link] as? URL {
                            uploadMediaToStorage(
                                imageData: nil,
                                videoURL: videoURL,
                                path: "videos",
                                type: .video,
                                currentIndex: currentIndex
                            ) { content in
                                if let content = content {
                                    contents.append(content)
                                }
                                pendingUploads -= 1
                                if pendingUploads == 0 {
                                    completion(contents.sorted(by: { $0.index < $1.index }))
                                }
                            }
                        } else {
                            print("无法获取视频 URL")
                            pendingUploads -= 1
                        }
                    } else if fileType == UTType.image.identifier {
                        // 处理图片附件
                        if let image = attachment.image {
                            pendingUploads += 1
                            uploadMediaToStorage(
                                imageData: image.pngData(),
                                videoURL: nil,
                                path: "images",
                                type: .image,
                                currentIndex: currentIndex
                            ) { content in
                                if let content = content {
                                    contents.append(content)
                                }
                                pendingUploads -= 1
                                if pendingUploads == 0 {
                                    completion(contents.sorted(by: { $0.index < $1.index }))
                                }
                            }
                        }
                    } else {
                        pendingUploads -= 1
                    }
                } else if let image = attachment.image {
                    // 处理没有 fileType 的图片附件
                    pendingUploads += 1
                    uploadMediaToStorage(
                        imageData: image.pngData(),
                        videoURL: nil,
                        path: "images",
                        type: .image,
                        currentIndex: currentIndex
                    ) { content in
                        if let content = content {
                            contents.append(content)
                        }
                        pendingUploads -= 1
                        if pendingUploads == 0 {
                            completion(contents.sorted(by: { $0.index < $1.index }))
                        }
                    }
                } else {
                    pendingUploads -= 1
                }
            } else if let link = attributes[.link] as? URL {
                let displayText = richText.attributedSubstring(from: range).string
                let content = TreasureContent(
                    type: .link,
                    content: link.absoluteString,
                    index: currentIndex,
                    displayText: displayText
                )
                contents.append(content)
                currentIndex += 1
            } else {
                let text = richText.attributedSubstring(from: range).string
                let content = TreasureContent(
                    type: .text,
                    content: text,
                    index: currentIndex
                )
                contents.append(content)
                currentIndex += 1
            }
        }

        if pendingUploads == 0 {
            completion(contents.sorted(by: { $0.index < $1.index }))
        }
    }

    private func uploadMediaToStorage(imageData: Data?, videoURL: URL?, path: String, type: ContentType, currentIndex: Int, completion: @escaping (TreasureContent?) -> Void) {
        let filename = UUID().uuidString
        let storageRef = Storage.storage().reference().child("\(path)/\(filename)")

        if let data = imageData {
            let metadata = StorageMetadata()
            metadata.contentType = "image/png"

            storageRef.putData(data, metadata: metadata) { metadata, error in
                if let error = error {
                    print("圖片上傳失敗：\(error.localizedDescription)")
                    completion(nil)
                    return
                }
                storageRef.downloadURL { url, error in
                    if let url = url {
                        let content = TreasureContent(type: type, content: url.absoluteString, index: currentIndex)
                        completion(content)
                    } else {
                        print("獲取下載URL失敗: \(error?.localizedDescription ?? "未知錯誤")")
                        completion(nil)
                    }
                }
            }
        } else if let videoURL = videoURL {
            let metadata = StorageMetadata()
            metadata.contentType = "video/mp4"

            storageRef.putFile(from: videoURL, metadata: metadata) { metadata, error in
                if let error = error {
                    print("視頻上傳失敗：\(error.localizedDescription)")
                    completion(nil)
                    return
                }
                storageRef.downloadURL { url, error in
                    if let url = url {
                        let content = TreasureContent(type: type, content: url.absoluteString, index: currentIndex)
                        completion(content)
                    } else {
                        print("獲取下載URL失敗: \(error?.localizedDescription ?? "未知錯誤")")
                        completion(nil)
                    }
                }
            }
        } else {
            completion(nil)
        }
    }
}
