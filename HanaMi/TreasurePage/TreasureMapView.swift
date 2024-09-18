import SwiftUI
import MapKit

struct TreasureMapView: View {
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var shouldZoomToUserLocation = true
    @ObservedObject var locationManager = LocationManager()
    @ObservedObject var treasureManager = TreasureManager()
    @State private var showTreasureDetail = false // 控制是否顯示寶藏詳情
    @State private var selectedTreasure: Treasure? // 當前選中的寶藏
    
    var body: some View {
        VStack {
            if let selectedLocationName = selectedLocationName {
                Text("選中的寶藏: \(selectedLocationName)")
            }
            
            // 使用 .viewTreasures 模式顯示寶藏標註
            CustomMapView(
                selectedCoordinate: $selectedCoordinate,
                selectedLocationName: $selectedLocationName,
                shouldZoomToUserLocation: $shouldZoomToUserLocation,
                selectedTreasure: $selectedTreasure,
                showTreasureDetail: $showTreasureDetail,
                locationManager: locationManager,
                treasureManager: treasureManager,
                mode: .viewTreasures // 顯示寶藏
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
