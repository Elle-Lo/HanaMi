import Combine
import SwiftUI
import MapKit

class LocationSearchViewModel: ObservableObject {
    @Published var searchResults: [MKMapItem] = []
    @Published var searchQuery: String = "" {
        didSet {
            searchLocations()
        }
    }
    @Published var errorMessage: String?
    private var localSearch: MKLocalSearch?
    var locationManager: LocationManager?

    func searchLocations() {
        
        guard !searchQuery.isEmpty else {
            self.searchResults = []
            self.errorMessage = nil
            return
        }
        
        localSearch?.cancel()

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.resultTypes = [.pointOfInterest, .address]

        localSearch = MKLocalSearch(request: request)
        localSearch?.start { [weak self] (response, error) in
            if let error = error {
                print("搜尋失敗: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorMessage = "搜尋失敗，請稍後再試"
                }
                return
            }

            if let mapItems = response?.mapItems {
                DispatchQueue.main.async {
                    self?.searchResults = mapItems
                    self?.errorMessage = nil
                }
            } else {
               
                DispatchQueue.main.async {
                    self?.searchResults = []
                    self?.errorMessage = "沒有找到相關地點"
                }
            }
        }
    }
}
