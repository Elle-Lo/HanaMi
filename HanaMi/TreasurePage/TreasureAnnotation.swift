import Foundation
import MapKit

class TreasureAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let treasureID: String
    let isUserTreasure: Bool 

    init(treasureSummary: TreasureSummary, isUserTreasure: Bool) {
        self.coordinate = CLLocationCoordinate2D(latitude: treasureSummary.latitude, longitude: treasureSummary.longitude)
        self.treasureID = treasureSummary.id
        self.isUserTreasure = isUserTreasure
    }
}
