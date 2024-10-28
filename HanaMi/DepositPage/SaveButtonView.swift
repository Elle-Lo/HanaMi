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
    let textContent: String
    let selectedMediaItems: [(url: URL, type: String)]
    @State private var isShowingSaveAnimation = false
    @Binding var errorMessage: String?
    @Binding var isSaving: Bool

    @StateObject var audioRecorder: AudioRecorder

    var firestoreService = FirestoreService()
    var onSave: () -> Void

    var body: some View {
        Button(action: {
            guard !isSaving else { return }
                        isSaving = true
            saveDataToFirestore()
        }) {
            Text(isSaving ? "Saving..." : "Save")
                .font(.custom("LexendDeca-Bold", size: 15))
                .foregroundColor(isSaving ? .white : .colorBrown)
                           .padding()
                           .background(isSaving ? .colorGray : .colorYellow)
                           .cornerRadius(10)
        }
        .disabled(isSaving)
        .opacity(isSaving ? 0.5 : 1.0)
    }
    
    private func saveDataToFirestore() {
       
        guard let coordinate = selectedCoordinate,
              let locationName = selectedLocationName else {
            errorMessage = "請選擇一個有效的地點"
            isSaving = false
            return
        }

        let trimmedText = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty && selectedMediaItems.isEmpty && audioRecorder.recordingURL == nil {
            errorMessage = "請輸入內容或上傳圖片、影片或音訊"
            isSaving = false
            return
        }

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

    private func extractContentsWithMediaUpload(_ textContent: String, completion: @escaping ([TreasureContent]) -> Void) {
        var contents: [TreasureContent] = []
        var pendingUploads = 0
        var currentIndex = 0

        if !textContent.isEmpty {
            let content = TreasureContent(type: .text, content: textContent, index: currentIndex)
            contents.append(content)
            currentIndex += 1
        }

        for item in selectedMediaItems {
            switch item.type {
            case "link":
                
                let linkContent = TreasureContent(type: .link, content: item.url.absoluteString, index: currentIndex)
                contents.append(linkContent)
                currentIndex += 1

            case "image":
            
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
                
            case "music":
               
                let musicContent = TreasureContent(type: .music, content: item.url.absoluteString, index: currentIndex)
                contents.append(musicContent)
                currentIndex += 1
                
            default:
                break
            }
        }

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

        if pendingUploads == 0 {
            completion(contents.sorted(by: { $0.index < $1.index }))
        }
    }

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
