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
        ZStack {
            // 顯示選中的寶藏名稱
            //            if let selectedLocationName = selectedLocationName {
            //                Text("選中的寶藏: \(selectedLocationName)")
            //                    .font(.headline)
            //                    .padding()
            //            }
            
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
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // 控制顯示模式的兩個按鈕
                HStack(spacing: 5) { // 縮小按鈕之間的間距
                    Button(action: {
                        isShowingAllTreasures = true
                        fetchTreasuresForCurrentBounds() // 全部宝藏
                    }) {
                        Image(systemName: "globe.asia.australia.fill")
                            .font(.system(size: 18)) // 縮小圖標大小
                            .foregroundColor(isShowingAllTreasures ? .colorBrown : .colorBrown)
                            .frame(width: 50, height: 40) // 調整按鈕框的大小
                            .background(isShowingAllTreasures ? Color.white : Color.clear)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 8) // 減少 padding

                    Button(action: {
                        isShowingAllTreasures = false
                        fetchTreasuresForCurrentBounds() // 个人宝藏
                    }) {
                        Image(systemName: "figure.wave")
                            .font(.system(size: 22)) // 縮小圖標大小
                            .foregroundColor(!isShowingAllTreasures ? .colorBrown : .colorBrown)
                            .frame(width: 50, height: 40) // 調整按鈕框的大小
                            .background(!isShowingAllTreasures ? Color.white : Color.clear)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 8) // 減少 padding
                }
                .padding(.vertical, 3) // 縮小垂直 padding
                .background(Color(hex: "FCEEDF"))
                .clipShape(Capsule())
                .shadow(radius: 5)
                .padding(.bottom, 40) // 調整區塊的底部距離

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
    
    // 根據是否顯示所有寶藏來加載地圖範圍內的寶藏
    func fetchTreasuresForCurrentBounds() {
        if let location = locationManager.location {
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

            let minLat = region.center.latitude - region.span.latitudeDelta / 2
            let maxLat = region.center.latitude + region.span.latitudeDelta / 2
            let minLng = region.center.longitude - region.span.longitudeDelta / 2
            let maxLng = region.center.longitude + region.span.longitudeDelta / 2
            
            // 抓取所有公開和個人寶藏
            if isShowingAllTreasures {
                treasureManager.fetchAllPublicAndUserTreasures(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { treasures in
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
