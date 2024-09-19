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
    let userID: String
    
    var body: some View {
        VStack {
            if selectedCoordinate != nil {
                Text("已選地點: \(selectedLocationName ?? "未知地點")")
            }

            CustomMapView(
                selectedCoordinate: $selectedCoordinate,
                selectedLocationName: $selectedLocationName,
                shouldZoomToUserLocation: $shouldZoomToUserLocation,
                selectedTreasure: .constant(nil),  // 不需要寶藏，設置為 nil
                showTreasureDetail: .constant(false),  // 不需要詳情，設置為 false
                isShowingAllTreasures: .constant(false),  // 固定為 false，因為不涉及寶藏顯示
                locationManager: locationManager,
                treasureManager: treasureManager,
                mode: .selectLocation,
                userID: userID
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
}
