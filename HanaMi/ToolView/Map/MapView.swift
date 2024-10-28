import SwiftUI
import MapKit

struct MapView: View {
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var shouldZoomToUserLocation = true
    @Binding var selectedTreasure: Treasure?
    @Binding var showTreasureDetail: Bool
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
                selectedTreasure: .constant(nil),
                showTreasureDetail: .constant(false),
                isShowingAllTreasures: .constant(false),  
                locationManager: locationManager,
                treasureManager: treasureManager,
                mode: .selectLocation,
                userID: userID
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
}
