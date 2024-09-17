import SwiftUI
import MapKit

struct SaveButtonView: View {
    let userID: String
    let selectedCoordinate: CLLocationCoordinate2D?
    let selectedLocationName: String?
    let selectedCategory: String
    let isPublic: Bool
    let contents: [TreasureContent]
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
        // 確認地點與類別選擇有效
        guard let coordinate = selectedCoordinate, let locationName = selectedLocationName else {
            errorMessage = "請選擇一個有效的地點"
            return
        }

        if selectedCategory.isEmpty {
            errorMessage = "請選擇一個類別"
            return
        }

        // 保存數據到 Firestore
        firestoreService.saveTreasure(userID: userID, coordinate: coordinate, locationName: locationName, category: selectedCategory, isPublic: isPublic, contents: contents) { result in
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
