import Foundation
import MapKit

// 自定義 MKAnnotation 類來表示寶藏
class TreasureAnnotation: NSObject, MKAnnotation {
    let treasureSummary: TreasureSummary
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: treasureSummary.latitude, longitude: treasureSummary.longitude)
    }
    
    var title: String? {
        return "寶藏" // 可以自定義標註的名稱
    }
    
    init(treasureSummary: TreasureSummary) {
        self.treasureSummary = treasureSummary
    }
}

