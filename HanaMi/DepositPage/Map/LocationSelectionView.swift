import SwiftUI
import MapKit

enum ActiveSheet: Identifiable {
    case map, search
    
    // 使用枚舉實例本身作為標識符
    var id: ActiveSheet { self }
}

struct LocationSelectionView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedLocationName: String?
    @Binding var shouldZoomToUserLocation: Bool
    @ObservedObject var locationManager: LocationManager // 傳遞 LocationManager
    @ObservedObject var searchViewModel: LocationSearchViewModel // 傳遞 SearchViewModel
    @State private var activeSheet: ActiveSheet? = nil // 管理當前活動的 sheet

    var body: some View {
        HStack {
            // 顯示地圖選擇地點的按鈕
            Button(action: {
                shouldZoomToUserLocation = true
                activeSheet = .map // 打開地圖 sheet
            }) {
                HStack {
                    // 顯示地名和經緯度
                    if let name = selectedLocationName, let coordinate = selectedCoordinate {
                        Text("\(name) - 經度: \(coordinate.longitude), 緯度: \(coordinate.latitude)")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    } else {
                        Text("選擇地點")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            // 搜尋按鈕
            Button(action: {
                activeSheet = .search // 打開搜索 sheet
            }) {
                Image(systemName: "magnifyingglass")
                    .padding(8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        // 使用 activeSheet 決定顯示的 sheet
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
