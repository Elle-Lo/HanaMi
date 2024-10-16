import SwiftUI
import MapKit

struct TreasureMapView: View {
    @State private var selectedTreasure: Treasure? = nil
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
                selectedTreasure: $selectedTreasure,  // 绑定选中的宝藏
                showTreasureDetail: $showTreasureDetail,  // 控制 Sheet 的显示
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
