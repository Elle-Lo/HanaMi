import SwiftUI
import MapKit

struct LocationSearchView: View {
    @ObservedObject var viewModel: LocationSearchViewModel
    @Binding var selectedCoordinate: CLLocationCoordinate2D? // 用於返回選定的地點坐標
    @Binding var selectedLocationName: String? // 用於返回選定的地點名稱
    @ObservedObject var locationManager: LocationManager // 用於獲取當前使用者的位置
    @Environment(\.presentationMode) var presentationMode // 用於關閉視圖

    var body: some View {
        VStack {
            // 搜尋框
            TextField("輸入地點名稱", text: $viewModel.searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .cornerRadius(8)

            // 如果有錯誤消息，顯示錯誤
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top)
            } else if viewModel.searchResults.isEmpty {
                Text("沒有結果")
                    .foregroundColor(.gray)
                    .padding(.top)
            }

            // 顯示搜索結果
            List(viewModel.searchResults, id: \.self) { result in
                Button(action: {
                    selectLocation(result)
                }) {
                    VStack(alignment: .leading) {
                        Text(result.name ?? "未知地點")
                        if let distance = calculateDistance(from: result.placemark.coordinate) {
                            Text("距離：\(String(format: "%.2f", distance)) 公里")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listRowBackground(Color(UIColor.systemGray6)) // 搜尋結果行的背景
            }
            .background(Color(UIColor.systemGray6)) // 設置列表背景

            Spacer()
        }
        .background(Color(UIColor.systemGray6)) // 整個視圖的背景
        .cornerRadius(10)
    }

    // 計算距離
    private func calculateDistance(from coordinate: CLLocationCoordinate2D) -> Double? {
        guard let userLocation = locationManager.location else { return nil }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: userLocation) / 1000 // 距離轉換為公里
    }

    // 選擇地點後更新坐標和名稱，並關閉搜尋視圖
    private func selectLocation(_ mapItem: MKMapItem) {
        selectedCoordinate = mapItem.placemark.coordinate
        selectedLocationName = mapItem.name ?? "未知地點" // 只更新名稱，經緯度單獨處理
        presentationMode.wrappedValue.dismiss() // 選擇後關閉 sheet
    }
}
