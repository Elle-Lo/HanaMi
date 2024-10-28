import MapKit
import SwiftUI

enum MapMode {
    case selectLocation
    case viewTreasures
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
    var mode: MapMode
    var userID: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, mode: mode, userID: userID)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        var mode: MapMode
        var userID: String 

        init(_ parent: CustomMapView, mode: MapMode, userID: String) {
            self.parent = parent
            self.mode = mode
            self.userID = userID
        }

            func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
             
                if mode == .viewTreasures {
                    let center = mapView.centerCoordinate
                    let radius = mapView.currentRadius()

                    let minLat = center.latitude - radius / 111.32
                    let maxLat = center.latitude + radius / 111.32
                    let minLng = center.longitude - radius / (111.32 * cos(center.latitude * .pi / 180))
                    let maxLng = center.longitude + radius / (111.32 * cos(center.latitude * .pi / 180))

                    if parent.isShowingAllTreasures {
                      
                        parent.treasureManager.fetchAllPublicAndUserTreasures(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { treasures in
                            DispatchQueue.main.async {
                                mapView.removeAnnotations(mapView.annotations)
                                let newAnnotations = treasures.map { treasure in
                                    TreasureAnnotation(treasureSummary: treasure, isUserTreasure: treasure.userID == self.parent.userID)
                                }
                                
                                mapView.addAnnotations(newAnnotations)
                            }
                        }
                    } else {
                   
                        parent.treasureManager.fetchUserTreasures(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng) { treasures in
                            DispatchQueue.main.async {
                                mapView.removeAnnotations(mapView.annotations)
                                for treasure in treasures {
                                    let annotation = TreasureAnnotation(treasureSummary: treasure, isUserTreasure: true)
                                    mapView.addAnnotation(annotation)
                                }
                            }
                        }
                    }

                }
            }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let treasureAnnotation = view.annotation as? TreasureAnnotation {
                print("Selected treasure annotation with ID: \(treasureAnnotation.treasureID)")
             
                parent.treasureManager.getTreasure(by: treasureAnnotation.treasureID)  { treasure in
                    if let treasure = treasure {
                        DispatchQueue.main.async {
                            self.parent.selectedTreasure = treasure
                            self.parent.showTreasureDetail = true
                        }
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil            
            }

            if let treasureAnnotation = annotation as? TreasureAnnotation {
                let identifier = "TreasureMarker"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                  
                    annotationView = MKMarkerAnnotationView(annotation: treasureAnnotation, reuseIdentifier: identifier)
                } else {
                    
                    annotationView?.annotation = treasureAnnotation
                }

                if let treasureImage = UIImage(named: "treasure")?.resized(to: CGSize(width: 20, height: 20)) {
                            annotationView?.glyphImage = UIImage(named: "treasure")
                        }
               
                annotationView?.markerTintColor = UIColor(red: 0.54, green: 0.27, blue: 0.07, alpha: 1.0)

                annotationView?.canShowCallout = false
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)

                annotationView?.accessibilityIdentifier = "TreasureAnnotation_\(treasureAnnotation.treasureID)"
                return annotationView
            }
            return nil
        }

        @objc func handleTapGesture(gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let tapLocation = gesture.location(in: mapView)
            let coordinate = mapView.convert(tapLocation, toCoordinateFrom: mapView)

            if mode == .selectLocation {
                parent.selectedCoordinate = coordinate
                DispatchQueue.main.async {
                    self.parent.selectedLocationName = "正在載入..."
                       }
                
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
        mapView.accessibilityIdentifier = "MapView" 
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

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
        
        let currentAnnotations = mapView.annotations.compactMap { $0 as? TreasureAnnotation }
      
        let newAnnotations = treasureManager.displayedTreasures.map { detailedTreasure in
            let isUserTreasure = (detailedTreasure.userID == userID)
            return TreasureAnnotation(treasureSummary: detailedTreasure, isUserTreasure: isUserTreasure)
        }
        
        if !newAnnotations.isEmpty {
            mapView.addAnnotations(newAnnotations)
        }
        
        if mode == .selectLocation, let coordinate = selectedCoordinate {
            let annotationsToRemove = mapView.annotations.filter { $0 is MKPointAnnotation }
            mapView.removeAnnotations(annotationsToRemove)
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
        
        let northWestCorner = CLLocationCoordinate2D(
            latitude: center.latitude - region.span.latitudeDelta / 2,
            longitude: center.longitude - region.span.longitudeDelta / 2
        )
        
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let northWestLocation = CLLocation(latitude: northWestCorner.latitude, longitude: northWestCorner.longitude)
        
        return centerLocation.distance(from: northWestLocation) 
    }
}
