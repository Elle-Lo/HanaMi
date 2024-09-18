import SwiftUI
import MapKit

struct MapView: View {
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var shouldZoomToUserLocation = true
    @Binding var selectedTreasure: Treasure?  // 可選的寶藏
    @Binding var showTreasureDetail: Bool     // 可選的顯示詳情
    @ObservedObject var locationManager = LocationManager()
    @ObservedObject var treasureManager = TreasureManager()

    var body: some View {
        VStack {
            if let selectedCoordinate = selectedCoordinate {
                Text("已選地點: \(selectedLocationName ?? "未知地點")")
            }

            CustomMapView(
                selectedCoordinate: $selectedCoordinate,
                selectedLocationName: $selectedLocationName,
                shouldZoomToUserLocation: $shouldZoomToUserLocation,
                selectedTreasure: .constant(nil),  // 這裡傳入 nil 作為默認值
                showTreasureDetail: .constant(false),  // 傳遞一個 false 的默認值
                locationManager: locationManager,
                treasureManager: treasureManager,
                mode: .selectLocation
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
}
