import Foundation
import MapKit

class TreasureAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let treasureID: String // 用于标记这个宝藏的唯一ID
    
    init(treasureSummary: TreasureSummary) {
        self.coordinate = CLLocationCoordinate2D(latitude: treasureSummary.latitude, longitude: treasureSummary.longitude)
        self.title = nil
        self.treasureID = treasureSummary.id // 从 TreasureSummary 中获取 ID
    }
}
