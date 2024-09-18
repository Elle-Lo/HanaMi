import SwiftUI
import MapKit

struct TreasureMapPage: View {
    // 狀態變數
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var shouldZoomToUserLocation = true
    @State private var showTreasureDetail = false // 控制是否顯示寶藏詳情
    @State private var selectedTreasure: Treasure? // 當前選中的寶藏
    
    @ObservedObject var locationManager = LocationManager()
    @ObservedObject var treasureManager = TreasureManager()
    
    var body: some View {
        VStack {
            // 顯示選中的寶藏名稱
            if let selectedLocationName = selectedLocationName {
                Text("選中的寶藏: \(selectedLocationName)")
                    .font(.headline)
                    .padding()
            }
            
            // CustomMapView 顯示地圖與寶藏標註
            CustomMapView(
                selectedCoordinate: $selectedCoordinate,
                selectedLocationName: $selectedLocationName,
                shouldZoomToUserLocation: $shouldZoomToUserLocation,
                selectedTreasure: $selectedTreasure, // 傳入寶藏
                showTreasureDetail: $showTreasureDetail, // 傳入是否顯示詳細視圖的狀態
                locationManager: locationManager,
                treasureManager: treasureManager,
                mode: .viewTreasures // 添加 mode: .viewTreasures，顯示寶藏標註
            )
            .edgesIgnoringSafeArea(.all) // 地圖填滿整個頁面
        }
        .navigationTitle("寶藏地圖")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTreasureDetail) {
            if let treasure = selectedTreasure {
                // 顯示寶藏詳情視圖
                TreasureDetailView(treasure: treasure)
            }
        }
        .onAppear {
            
            shouldZoomToUserLocation = true
            // 打開地圖時加載用戶當前位置及附近寶藏
            if let coordinate = locationManager.location?.coordinate {
                treasureManager.fetchTreasuresNear(coordinate: coordinate, radius: 3000)
            }
        }
    }
}
