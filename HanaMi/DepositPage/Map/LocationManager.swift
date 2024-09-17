import SwiftUI
import MapKit
import CoreLocation

// LocationManager - 負責取得使用者當前位置
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation? // 儲存使用者的位置
    private var locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()  // 請求位置授權
        locationManager.startUpdatingLocation() // 開始更新使用者位置
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
        self.location = latestLocation // 儲存最新的使用者位置
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Failed to get location: \(error.localizedDescription)")
        }
}
