import SwiftUI
import MapKit
import FirebaseStorage

struct SaveButtonView: View {
    let userID: String
    let selectedCoordinate: CLLocationCoordinate2D?
    let selectedLocationName: String?
    let selectedCategory: String
    let isPublic: Bool
    let contents: [TreasureContent] // 包含文字、圖片、連結等
    @Binding var errorMessage: String?

    var firestoreService = FirestoreService()
    let storage = Storage.storage() // Firebase Storage 實例

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
        // 確認地點與類別選擇有效
        guard let coordinate = selectedCoordinate, let locationName = selectedLocationName else {
            errorMessage = "請選擇一個有效的地點"
            return
        }

        if selectedCategory.isEmpty {
            errorMessage = "請選擇一個類別"
            return
        }

        // 開始處理圖片上傳，如果有圖片
        uploadImagesAndSaveTreasure(coordinate: coordinate, locationName: locationName)
    }

    // 上傳圖片並保存數據到 Firestore
    private func uploadImagesAndSaveTreasure(coordinate: CLLocationCoordinate2D, locationName: String) {
        var updatedContents = contents
        let dispatchGroup = DispatchGroup()

        for (index, content) in contents.enumerated() {
            if content.type == .image, let imageData = Data(base64Encoded: content.content) {
                dispatchGroup.enter()

                let imageRef = storage.reference().child("images/\(UUID().uuidString).png")

                imageRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        print("圖片上傳失敗: \(error.localizedDescription)")
                        dispatchGroup.leave()
                        return
                    }

                    // 獲取圖片的下載 URL
                    imageRef.downloadURL { url, error in
                        if let error = error {
                            print("獲取圖片 URL 失敗: \(error.localizedDescription)")
                        } else if let downloadURL = url {
                            // 更新內容中的圖片 URL
                            updatedContents[index].content = downloadURL.absoluteString
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        }

        // 當所有圖片都上傳完畢後，保存到 Firestore
        dispatchGroup.notify(queue: .main) {
            self.saveTreasureToFirestore(coordinate: coordinate, locationName: locationName, updatedContents: updatedContents)
        }
    }

    // 保存寶藏數據到 Firestore
    private func saveTreasureToFirestore(coordinate: CLLocationCoordinate2D, locationName: String, updatedContents: [TreasureContent]) {
        firestoreService.saveTreasure(userID: userID, coordinate: coordinate, locationName: locationName, category: selectedCategory, isPublic: isPublic, contents: updatedContents) { result in
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
