import SwiftUI
import MapKit

struct TreasureMapView: View {
    @State private var selectedTreasure: Treasure?
    @State private var showTreasureDetail = false
    @State private var isShowingAllTreasures = true

    @ObservedObject var treasureManager = TreasureManager()
    @ObservedObject var locationManager = LocationManager()
    let userID: String
    
    var body: some View {
        ZStack {
            CustomMapView(
                selectedCoordinate: .constant(nil),
                selectedLocationName: .constant(nil),
                shouldZoomToUserLocation: .constant(false),
                selectedTreasure: $selectedTreasure,
                showTreasureDetail: $showTreasureDetail, 
                isShowingAllTreasures: $isShowingAllTreasures,
                locationManager: locationManager,
                treasureManager: treasureManager,
                mode: .viewTreasures, 
                userID: userID
            )
            .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $showTreasureDetail) {
            if let treasure = selectedTreasure {
                TreasureDetailView(treasure: treasure)
            }
        }
    }
}
