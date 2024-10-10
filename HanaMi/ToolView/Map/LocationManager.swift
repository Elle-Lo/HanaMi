//import SwiftUI
//import MapKit
//import CoreLocation
//
//// LocationManager - 負責取得使用者當前位置
//class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    @Published var location: CLLocation? // 儲存使用者的位置
//    private var locationManager = CLLocationManager()
//
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.requestWhenInUseAuthorization()  // 請求位置授權
//        locationManager.startUpdatingLocation() // 開始更新使用者位置
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let latestLocation = locations.first else { return }
//        self.location = latestLocation // 儲存最新的使用者位置
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//            print("Failed to get location: \(error.localizedDescription)")
//        }
//}

import Foundation
import CoreLocation
import Combine
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    private var locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }

    // 新增一個 region 屬性，計算基於當前位置的區域
    var region: MKCoordinateRegion? {
        guard let location = location else {
            return nil
        }
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        return MKCoordinateRegion(center: location.coordinate, span: span)
    }
}

