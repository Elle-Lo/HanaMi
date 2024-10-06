import SwiftUI
import MapKit

enum ActiveSheet: Identifiable {
    case map, search
    
    var id: ActiveSheet { self }
}

struct LocationSelectionView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedLocationName: String?
    @Binding var shouldZoomToUserLocation: Bool
    @ObservedObject var locationManager: LocationManager
    
    @ObservedObject var searchViewModel: LocationSearchViewModel
    @State private var activeSheet: ActiveSheet? = nil
    let userID: String
    
    var body: some View {
        HStack {
            
            Button(action: {
                activeSheet = .search // 打開搜索 sheet
            }) {
                Image(systemName: "magnifyingglass")
                    .padding(8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            // 顯示地圖選擇地點的按鈕
            Button(action: {
                shouldZoomToUserLocation = true // 確保縮放到使用者位置
                activeSheet = .map // 打開地圖 sheet
            }) {
                HStack {
                    // 顯示地名和經緯度
                    if let name = selectedLocationName {
                        Text("\(name)")
                            .foregroundColor(.colorBrown)
                            .font(.custom("LexendDeca-SemiBold", size: 13))
                            .padding(12)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    } else {
                        Text("選擇地點")
                            .foregroundColor(.colorBrown)
                            .font(.custom("LexendDeca-SemiBold", size: 13))
                            .padding(12)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal)
        // 使用 activeSheet 決定顯示的 sheet
        .sheet(item: $activeSheet) { item in
            switch item {
            case .map:
                CustomMapView(
                    selectedCoordinate: $selectedCoordinate,
                    selectedLocationName: $selectedLocationName,
                    shouldZoomToUserLocation: $shouldZoomToUserLocation,
                    selectedTreasure: .constant(nil),
                    showTreasureDetail: .constant(false),
                    isShowingAllTreasures: .constant(false),
                    locationManager: locationManager,
                    treasureManager: TreasureManager(), // 傳入空的 treasureManager
                    mode: .selectLocation,
                    userID: userID
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
