import MapKit
import SwiftUI

enum MapMode {
    case selectLocation // 選擇地點
    case viewTreasures  // 顯示寶藏
}

struct CustomMapView: UIViewRepresentable {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedLocationName: String?
    @Binding var shouldZoomToUserLocation: Bool
    @Binding var selectedTreasure: Treasure? // 選擇的寶藏，用於顯示寶藏詳細信息
    @Binding var showTreasureDetail: Bool    // 是否顯示寶藏詳細視圖
    
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var treasureManager: TreasureManager
    var mode: MapMode // 保留 mode 來區分行為

    func makeCoordinator() -> Coordinator {
        Coordinator(self, mode: mode)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        var mode: MapMode

        init(_ parent: CustomMapView, mode: MapMode) {
            self.parent = parent
            self.mode = mode
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
                    if let treasureAnnotation = view.annotation as? TreasureAnnotation {
                        let treasureID = treasureAnnotation.treasureSummary.id
                        // 使用 treasureID 從 Firebase 中查詢寶藏的詳細資料
                        parent.treasureManager.fetchTreasureDetails(treasureID: treasureID) { result in
                            switch result {
                            case .success(let treasure):
                                DispatchQueue.main.async {
                                    self.parent.selectedTreasure = treasure
                                    self.parent.showTreasureDetail = true
                                }
                            case .failure(let error):
                                print("Error fetching treasure details: \(error)")
                            }
                        }
                    }
                }
        // 當地圖範圍發生變化時觸發
                func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
                    if mode == .viewTreasures {
                        let center = mapView.centerCoordinate
                        parent.treasureManager.fetchTreasuresNear(coordinate: center, radius: 3000)
                    }
                }

                // 為寶藏提供自定義的標註視圖
                func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
                    if annotation is MKUserLocation {
                        return nil // 不自定義使用者位置的標註
                    }

                    // 使用自定義寶藏標註
                    if mode == .viewTreasures {
                        let identifier = "Treasure"
                        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                        if annotationView == nil {
                            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                            annotationView?.canShowCallout = true
                            annotationView?.image = UIImage(named: "treasure") // 自定義寶藏圖標
                            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) // 詳細信息按鈕
                        } else {
                            annotationView?.annotation = annotation
                        }
                        return annotationView
                    }

                    return nil
                }


            func makeUIView(context: Context) -> MKMapView {
                let mapView = MKMapView()
                mapView.delegate = context.coordinator

                if mode == .selectLocation {
                    let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTapGesture))
                    mapView.addGestureRecognizer(tapGesture)
                }

                mapView.showsUserLocation = true

                return mapView
            }

        // 處理地圖點擊事件，根據模式進行不同的處理
        @objc func handleTapGesture(gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let tapLocation = gesture.location(in: mapView)
            let coordinate = mapView.convert(tapLocation, toCoordinateFrom: mapView)

            if mode == .selectLocation { // 如果是選擇地點模式，則更新父視圖的座標
                parent.selectedCoordinate = coordinate
                parent.selectedLocationName = "選中的地點"

                // 反向地理編碼以獲取地點名稱
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let placemark = placemarks?.first {
                        let name = placemark.name ?? "未知地點"
                        DispatchQueue.main.async {
                            self.parent.selectedLocationName = name
                        }
                    }
                }
            }
        }
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

        // 如果是選擇地點模式，添加點擊手勢
        if mode == .selectLocation {
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTapGesture))
            mapView.addGestureRecognizer(tapGesture)
        }

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
            if shouldZoomToUserLocation, let userLocation = locationManager.location?.coordinate {
                let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                mapView.setRegion(region, animated: true)
                shouldZoomToUserLocation = false
            }

            if mode == .selectLocation, let coordinate = selectedCoordinate {
                mapView.removeAnnotations(mapView.annotations)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = selectedLocationName
                mapView.addAnnotation(annotation)
            }

        if mode == .viewTreasures {
            for treasure in treasureManager.displayedTreasures {
                let annotation = TreasureAnnotation(treasureSummary: treasure)
                mapView.addAnnotation(annotation)
            }
        }
    }
}
