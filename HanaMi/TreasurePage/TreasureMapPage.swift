import SwiftUI
import MapKit

struct TreasureMapPage: View {
    // 狀態變數
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var shouldZoomToUserLocation = true
    @State private var showTreasureDetail = false // 控制是否顯示寶藏詳情
    @State private var selectedTreasure: Treasure? // 當前選中的寶藏
    @State private var isShowingAllTreasures = true // 判斷是否顯示全部寶藏
    
    @ObservedObject var locationManager = LocationManager()
    @ObservedObject var treasureManager = TreasureManager()
    
    let userID: String
    
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
                            selectedTreasure: $selectedTreasure,
                            showTreasureDetail: $showTreasureDetail,
                            isShowingAllTreasures: $isShowingAllTreasures, // 傳遞是否顯示全部寶藏
                            locationManager: locationManager,
                            treasureManager: treasureManager,
                            mode: .viewTreasures,
                            userID: userID
                        )
            .edgesIgnoringSafeArea(.all) // 地圖填滿整個頁面
            
            // 控制顯示模式的兩個按鈕
            HStack {
                Button(action: {
                    isShowingAllTreasures = true
                    fetchTreasuresForCurrentBounds() // 全部宝藏
                }) {
                    Image(systemName: "globe")
                        .font(.largeTitle)
                }
                .padding()
                
                Button(action: {
                    isShowingAllTreasures = false
                    fetchTreasuresForCurrentBounds() // 个人宝藏
                }) {
                    Image(systemName: "person")
                        .font(.largeTitle)
                }
                .padding()
            }
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
            fetchTreasuresForCurrentBounds() // 首次加载宝藏
        }
    }
    
    func fetchTreasuresForCurrentBounds() {
        if let location = locationManager.location {
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

            let minLat = region.center.latitude - region.span.latitudeDelta / 2
            let maxLat = region.center.latitude + region.span.latitudeDelta / 2
            let minLng = region.center.longitude - region.span.longitudeDelta / 2
            let maxLng = region.center.longitude + region.span.longitudeDelta / 2
            
            if isShowingAllTreasures {
                // 抓取所有公開和個人寶藏
                treasureManager.fetchAllPublicTreasures(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { treasures in
                    treasureManager.displayedTreasures = treasures
                }
            } else {
                // 只抓取個人寶藏
                treasureManager.fetchUserTreasures(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { treasures in
                    treasureManager.displayedTreasures = treasures
                }
            }
        }
    }

}