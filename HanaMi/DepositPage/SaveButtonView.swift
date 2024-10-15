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
    let textContent: String  // 純文字內容
    let selectedMediaItems: [(url: URL, type: String)]  // 已選擇的媒體項目
    @State private var isShowingSaveAnimation = false
    @Binding var errorMessage: String?
    @Binding var isSaving: Bool

    @StateObject var audioRecorder: AudioRecorder

    var firestoreService = FirestoreService()
    var onSave: () -> Void

    var body: some View {
        Button(action: {
            guard !isSaving else { return }  // 如果正在儲存則跳過
                        isSaving = true  // 禁用按鈕
            saveDataToFirestore()
        }) {
            Text(isSaving ? "Saving..." : "Save")
                .font(.custom("LexendDeca-Bold", size: 15))
                .foregroundColor(isSaving ? .white : .colorBrown)
                           .padding()
                           .background(isSaving ? .colorGray : .colorYellow)
                           .cornerRadius(10)
        }
        .disabled(isSaving)  // 禁用按鈕
        .opacity(isSaving ? 0.5 : 1.0)  // 上傳中降低透明度
    }
    
    private func saveDataToFirestore() {
        // 檢查是否選擇了有效的地點
        guard let coordinate = selectedCoordinate,
              let locationName = selectedLocationName else {
            errorMessage = "請選擇一個有效的地點"
            isSaving = false
            return
        }

        // 檢查是否輸入了文本、選擇了媒體項目，或是有錄音
        let trimmedText = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty && selectedMediaItems.isEmpty && audioRecorder.recordingURL == nil {
            errorMessage = "請輸入內容或上傳圖片、影片或音訊"
            isSaving = false
            return
        }

        // 開始提取內容並上傳
        extractContentsWithMediaUpload(textContent) { processedContents in
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
                        isSaving = false
                    }
                }
            }
        }
    }

    // 提取文字及媒體並處理上傳
    private func extractContentsWithMediaUpload(_ textContent: String, completion: @escaping ([TreasureContent]) -> Void) {
        var contents: [TreasureContent] = []
        var pendingUploads = 0
        var currentIndex = 0

        // 儲存純文字
        if !textContent.isEmpty {
            let content = TreasureContent(type: .text, content: textContent, index: currentIndex)
            contents.append(content)
            currentIndex += 1
        }

        // 處理選擇的媒體項目
        for item in selectedMediaItems {
            switch item.type {
            case "link":
                // 連結類型處理
                let linkContent = TreasureContent(type: .link, content: item.url.absoluteString, index: currentIndex)
                contents.append(linkContent)
                currentIndex += 1

            case "image":
                // 圖片類型處理
                if let image = UIImage(contentsOfFile: item.url.path) {
                    pendingUploads += 1
                    uploadMediaToStorage(imageData: image.pngData(), mediaURL: nil, path: "images", type: .image, currentIndex: currentIndex) { content in
                        if let content = content {
                            contents.append(content)
                        }
                        pendingUploads -= 1
                        if pendingUploads == 0 {
                            completion(contents)
                        }
                    }
                    currentIndex += 1
                }

            case "video":
                // 視頻類型處理
                pendingUploads += 1
                uploadMediaToStorage(imageData: nil, mediaURL: item.url, path: "videos", type: .video, currentIndex: currentIndex) { content in
                    if let content = content {
                        contents.append(content)
                    }
                    pendingUploads -= 1
                    if pendingUploads == 0 {
                        completion(contents)
                    }
                }
                currentIndex += 1

            case "audio":
                // 音訊類型處理
                pendingUploads += 1
                uploadMediaToStorage(imageData: nil, mediaURL: item.url, path: "audios", type: .audio, currentIndex: currentIndex) { content in
                    if let content = content {
                        contents.append(content)
                    }
                    pendingUploads -= 1
                    if pendingUploads == 0 {
                        completion(contents)
                    }
                }
                currentIndex += 1

            default:
                break
            }
        }

        // 如果有音檔則上傳音檔
        if let localAudioURL = audioRecorder.recordingURL {
            pendingUploads += 1
            uploadMediaToStorage(imageData: nil, mediaURL: localAudioURL, path: "audios", type: .audio, currentIndex: currentIndex) { content in
                if let content = content {
                    contents.append(content)
                }
                try? FileManager.default.removeItem(at: localAudioURL)
                pendingUploads -= 1
                if pendingUploads == 0 {
                    completion(contents.sorted(by: { $0.index < $1.index }))
                }
            }
            currentIndex += 1
        }

        // 當沒有待處理的上傳時，完成處理
        if pendingUploads == 0 {
            completion(contents.sorted(by: { $0.index < $1.index }))
        }
    }

    // 上傳媒體到Firebase Storage
    private func uploadMediaToStorage(imageData: Data?, mediaURL: URL?, path: String, type: ContentType, currentIndex: Int, completion: @escaping (TreasureContent?) -> Void) {
        let filename = UUID().uuidString + (type == .video ? ".mp4" : ".png")
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
            metadata.contentType = "video/mp4"

            storageRef.putFile(from: mediaURL, metadata: metadata) { metadata, error in
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
