import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit
import CoreLocation

struct DepositPage: View {
    @State private var isPublic: Bool = true
        @State private var categories: [String] = ["Creative", "Technology", "Health", "Education"] // 示例類別
        @State private var selectedCategory: String = "Creative"
        @State private var selectedCoordinate: CLLocationCoordinate2D?
        @State private var selectedLocationName: String? = "未知地點"
        @State private var shouldZoomToUserLocation: Bool = true
        @State private var errorMessage: String?
        @State private var activeSheet: ActiveSheet? = nil
    
        @StateObject private var locationManager = LocationManager()
        @StateObject private var searchViewModel = LocationSearchViewModel()
    
    let userID = "g61HUemIJIRIC1wvvIqa"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 公開/私人切換按鈕 和 類別選擇
            HStack(spacing: 20) {
                Button(action: {
                    isPublic.toggle()
                }) {
                    Text(isPublic ? "公開" : "私人")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                        .padding()
                        .frame(width: 80)
                        .foregroundColor(isPublic ? .white : .gray)
                        .background(isPublic ? Color.orange : Color(UIColor.systemGray5))
                        .cornerRadius(10)
                }
                CategorySelectionView(selectedCategory: $selectedCategory, categories: $categories, userID: userID)
            }
            .padding(.horizontal)

            // 地點選擇部分
            LocationSelectionView(
                selectedCoordinate: $selectedCoordinate,
                selectedLocationName: $selectedLocationName,
                shouldZoomToUserLocation: $shouldZoomToUserLocation,
                locationManager: locationManager, // 傳遞 LocationManager
                searchViewModel: searchViewModel // 傳遞 SearchViewModel
            )
            
            Spacer()
            
            // 保存按鈕與錯誤訊息
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            SaveButtonView(
                userID: userID,
                selectedCoordinate: selectedCoordinate,
                selectedLocationName: selectedLocationName,
                selectedCategory: selectedCategory,
                isPublic: isPublic,
                errorMessage: $errorMessage // 傳遞錯誤訊息
            )
        }
        .sheet(item: $activeSheet) { item in
                    switch item {
                    case .map:
                        MapView(
                            selectedCoordinate: $selectedCoordinate,
                            selectedLocationName: $selectedLocationName,
                            shouldZoomToUserLocation: $shouldZoomToUserLocation
                        )
                    case .search:
                        LocationSearchView(
                            viewModel: searchViewModel,
                            selectedCoordinate: $selectedCoordinate,
                            selectedLocationName: $selectedLocationName,
                            locationManager: locationManager
                        )
                    }
                }
            }
        }

struct SaveButtonView: View {
    let db = Firestore.firestore()
    let userID: String
    let selectedCoordinate: CLLocationCoordinate2D?
    let selectedLocationName: String?
    let selectedCategory: String
    let isPublic: Bool
    @Binding var errorMessage: String?

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
        // 校驗地點和類別是否正確選擇
        guard let coordinate = selectedCoordinate, let locationName = selectedLocationName else {
            errorMessage = "請選擇一個有效的地點"
            return
        }

        if selectedCategory.isEmpty {
            errorMessage = "請選擇一個類別"
            return
        }

        let data: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "locationName": locationName,
            "category": selectedCategory,
            "isPublic": isPublic,
            "timestamp": Timestamp() // 添加時間戳
        ]

        db.collection("Users").document(userID).setData(data, merge: true) { error in
            if let error = error {
                errorMessage = "保存數據失敗: \(error.localizedDescription)"
            } else {
                errorMessage = "數據保存成功"
                print("Data saved successfully")
            }
        }
    }
}


#Preview {
    DepositPage()
}
