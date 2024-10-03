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
    
    @StateObject var audioRecorder: AudioRecorder

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
        var videoLink: URL? // 保存影片連結的變數
        var audioLink: URL? // 保存音訊連結的變數

        let fullRange = NSRange(location: 0, length: richText.length)

        // 遍歷富文本中的附件，檢查是否有圖片或視頻需要上傳
        richText.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? NSTextAttachment {
                currentIndex += 1

                if let fileType = attachment.fileType {
                    if fileType == UTType.movie.identifier {
                        // 處理視頻附件
                        pendingUploads += 1
                        if let videoURL = attributes[.link] as? URL {
                            // 保存影片的本地連結
                            videoLink = videoURL

                            // 開始上傳影片到 Firebase Storage
                            uploadMediaToStorage(
                                imageData: nil,
                                mediaURL: videoURL,
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
                            print("無法獲取視頻 URL")
                            pendingUploads -= 1
                        }
                    } else if fileType == UTType.image.identifier {
                        // 處理圖片附件
                        if let image = attachment.image {
                            pendingUploads += 1
                            uploadMediaToStorage(
                                imageData: image.pngData(),
                                mediaURL: nil,
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
                    // 處理沒有 fileType 的圖片附件
                    pendingUploads += 1
                    uploadMediaToStorage(
                        imageData: image.pngData(),
                        mediaURL: nil,
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

        // 如果有音檔則上傳音檔
        if let localAudioURL = audioRecorder.recordingURL {
            pendingUploads += 1
            uploadMediaToStorage(
                imageData: nil,
                mediaURL: localAudioURL,
                path: "audios",
                type: .audio,
                currentIndex: currentIndex
            ) { content in
                if let content = content {
                    contents.append(content)
                }
                try? FileManager.default.removeItem(at: localAudioURL)
                
                pendingUploads -= 1
                if pendingUploads == 0 {
                    completion(contents.sorted(by: { $0.index < $1.index }))
                }
            }
        }

        if pendingUploads == 0 {
            completion(contents.sorted(by: { $0.index < $1.index }))
        }
    }

    // 上傳多媒體內容的函數
    private func uploadMediaToStorage(imageData: Data?, mediaURL: URL?, path: String, type: ContentType, currentIndex: Int, completion: @escaping (TreasureContent?) -> Void) {
        let filename = (type == .audio) ? UUID().uuidString + ".m4a" : UUID().uuidString + (type == .video ? ".mp4" : "") // 為影片添加 .mp4 後綴
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
        } else if let mediaURL = mediaURL {
            let metadata = StorageMetadata()
            metadata.contentType = (type == .audio) ? "audio/m4a" : "video/mp4"

            storageRef.putFile(from: mediaURL, metadata: metadata) { metadata, error in
                if let error = error {
                    print("\(type == .audio ? "音檔" : "視頻")上傳失敗：\(error.localizedDescription)")
                    completion(nil)
                    return
                }
                storageRef.downloadURL { url, error in
                    if let url = url {
                        print("上傳成功，下載 URL: \(url.absoluteString)")
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
