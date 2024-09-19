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
    @Binding var selectedTreasure: Treasure?
    @Binding var showTreasureDetail: Bool
    @Binding var isShowingAllTreasures: Bool

    @ObservedObject var locationManager: LocationManager
    @ObservedObject var treasureManager: TreasureManager
    var mode: MapMode // 保留 mode 來區分行為
    var userID: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, mode: mode, userID: userID)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        var mode: MapMode
        var userID: String // 动态传递 userID


        init(_ parent: CustomMapView, mode: MapMode, userID: String) {
            self.parent = parent
            self.mode = mode
            self.userID = userID
        }

        // 当地图范围改变时，重新加载标注
            func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
                // 确认是宝藏显示模式
                if mode == .viewTreasures {
                    let center = mapView.centerCoordinate
                    let radius = mapView.currentRadius()

                    // 根据地图的中心和半径计算最小和最大经纬度
                    let minLat = center.latitude - radius / 111.32
                    let maxLat = center.latitude + radius / 111.32
                    let minLng = center.longitude - radius / (111.32 * cos(center.latitude * .pi / 180))
                    let maxLng = center.longitude + radius / (111.32 * cos(center.latitude * .pi / 180))

                    // 加载新的标注
                    if parent.isShowingAllTreasures {
                        // 加载所有公开的宝藏
                        parent.treasureManager.fetchAllPublicTreasures(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { treasures in
                            DispatchQueue.main.async {
                                mapView.removeAnnotations(mapView.annotations) // 清除旧的标注
                                for treasure in treasures {
                                    let annotation = TreasureAnnotation(treasureSummary: treasure)
                                    mapView.addAnnotation(annotation)
                                }
                            }
                        }
                    } else {
                        // 加载当前用户的宝藏
                        parent.treasureManager.fetchUserTreasures(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { treasures in
                            DispatchQueue.main.async {
                                mapView.removeAnnotations(mapView.annotations) // 清除旧的标注
                                for treasure in treasures {
                                    let annotation = TreasureAnnotation(treasureSummary: treasure)
                                    mapView.addAnnotation(annotation)
                                }
                            }
                        }
                    }
                }
            }
        
        // 当用户点击标注时，获取宝藏详细信息并显示 Sheet
           func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
               if let treasureAnnotation = view.annotation as? TreasureAnnotation {
                   // 调用 TreasureManager 来获取宝藏详细信息
                   print("Selected treasure annotation with ID: \(treasureAnnotation.treasureID)")  // 添加日志
                   parent.treasureManager.getTreasure(by: treasureAnnotation.treasureID, for: userID) { treasure in
                       if let treasure = treasure {
                           DispatchQueue.main.async {
                               self.parent.selectedTreasure = treasure  // 更新选中的宝藏
                               self.parent.showTreasureDetail = true    // 显示 Sheet
                           }
                       }
                   }
               }
           }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil // 不自定义用户位置的标注
            }

            if let treasureAnnotation = annotation as? TreasureAnnotation {
                let identifier = "TreasureMarker"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    // 创建新的 MKMarkerAnnotationView 实例
                    annotationView = MKMarkerAnnotationView(annotation: treasureAnnotation, reuseIdentifier: identifier)
                } else {
                    // 如果视图被复用，需要重新设置 annotation，确保视图被正确配置
                    annotationView?.annotation = treasureAnnotation
                }

                if let treasureImage = UIImage(named: "treasure")?.resized(to: CGSize(width: 20, height: 20)) {
                            annotationView?.glyphImage = UIImage(named: "treasure") // 使用缩放后的图标
                        }
               
                annotationView?.markerTintColor = UIColor(red: 0.54, green: 0.27, blue: 0.07, alpha: 1.0) // 自定义的气球颜色

                // 启用 callout，右侧添加详细信息按钮
                annotationView?.canShowCallout = true
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)

                return annotationView
            }

            return nil
        }

        // 處理點擊手勢，用於選擇地點模式
        @objc func handleTapGesture(gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let tapLocation = gesture.location(in: mapView)
            let coordinate = mapView.convert(tapLocation, toCoordinateFrom: mapView)

            if mode == .selectLocation { // 如果是選擇地點模式
                parent.selectedCoordinate = coordinate
//                parent.selectedLocationName = "選中的地點"

                // 使用反向地理編碼獲取地點名稱
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
        // 检查是否应该缩放到用户位置
        if shouldZoomToUserLocation, let userLocation = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
            shouldZoomToUserLocation = false
        }
        
        // 避免重复添加相同的标注
        let currentAnnotations = mapView.annotations.compactMap { $0 as? TreasureAnnotation }
        let newAnnotations = treasureManager.displayedTreasures.filter { treasure in
            // 过滤掉已经存在的标注
            !currentAnnotations.contains(where: { $0.treasureID == treasure.id })
        }.map { TreasureAnnotation(treasureSummary: $0) }
        
        // 只添加新的标注
        if !newAnnotations.isEmpty {
            mapView.addAnnotations(newAnnotations)
        }
        
        // 如果有选择的坐标，则更新标注
        if mode == .selectLocation, let coordinate = selectedCoordinate {
            let annotationsToRemove = mapView.annotations.filter { $0 is MKPointAnnotation }
            mapView.removeAnnotations(annotationsToRemove) // 先移除之前的选中点
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = selectedLocationName
            mapView.addAnnotation(annotation)
        }
    }
}

extension MKMapView {
    func currentRadius() -> Double {
        let region = self.region
        let center = region.center
        
        // 使用地图区域的中心点和 span 来计算半径
        let northWestCorner = CLLocationCoordinate2D(
            latitude: center.latitude - region.span.latitudeDelta / 2,
            longitude: center.longitude - region.span.longitudeDelta / 2
        )
        
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let northWestLocation = CLLocation(latitude: northWestCorner.latitude, longitude: northWestCorner.longitude)
        
        return centerLocation.distance(from: northWestLocation) // 返回半径（单位：米）
    }
}


