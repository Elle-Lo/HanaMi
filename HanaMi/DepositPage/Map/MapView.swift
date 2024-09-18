import SwiftUI
import MapKit
import CoreLocation

struct CustomMapView: UIViewRepresentable {
    @Binding var selectedCoordinate: CLLocationCoordinate2D? // 傳遞所選座標
    @Binding var selectedLocationName: String? // 傳遞地點名稱
    @Binding var shouldZoomToUserLocation: Bool
    @ObservedObject var locationManager: LocationManager // 傳入 LocationManager

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        @objc func handleTapGesture(gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let tapLocation = gesture.location(in: mapView)
            let coordinate = mapView.convert(tapLocation, toCoordinateFrom: mapView)
            
            // 更新父視圖的座標
            parent.selectedCoordinate = coordinate
            
            // 使用地理編碼反向查詢地點名稱
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    let name = placemark.name ?? "未知地點"
                    DispatchQueue.main.async {
                        // 只更新地點名稱，不將經緯度合併
                        self.parent.selectedLocationName = name
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // 創建 MKMapView 並設置點擊手勢
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // 添加點擊手勢識別器
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTapGesture))
        mapView.addGestureRecognizer(tapGesture)
        
        // 顯示使用者位置
        mapView.showsUserLocation = true
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 確保每次打開地圖時都會縮放至使用者當前位置
        if shouldZoomToUserLocation, let userLocation = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // 你想要的縮放級別
            )
            mapView.setRegion(region, animated: true)
            // 延遲設置 shouldZoomToUserLocation 為 false，確保地圖正確縮放
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.shouldZoomToUserLocation = false
            }
        }
        
        // 如果在地圖上點擊，則更新圖標，但不縮放地圖
        if let coordinate = selectedCoordinate {
            // 檢查當前標註是否已存在，避免重複添加
            if mapView.annotations.isEmpty || mapView.annotations.first?.coordinate.latitude != coordinate.latitude || mapView.annotations.first?.coordinate.longitude != coordinate.longitude {
                mapView.removeAnnotations(mapView.annotations) // 清除舊的標註
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                mapView.addAnnotation(annotation)
            }
        }
    }
}

// 地圖顯示視圖
struct MapView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedLocationName: String?
    @Binding var shouldZoomToUserLocation: Bool

    @ObservedObject var locationManager = LocationManager() // LocationManager 傳入

    var body: some View {
        VStack {
            // 顯示選擇的經緯度與地點名稱
            if let selectedCoordinate = selectedCoordinate {
                Text("選擇的地點: \(selectedLocationName ?? "未知地點")")
                    .padding()
            } else {
                Text("無法取得位置資訊")
                    .padding()
            }

            // 使用自定義的 CustomMapView 作為地圖
            CustomMapView(
                selectedCoordinate: $selectedCoordinate,
                selectedLocationName: $selectedLocationName,
                shouldZoomToUserLocation: $shouldZoomToUserLocation,
                locationManager: locationManager // 傳入 LocationManager
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
}
