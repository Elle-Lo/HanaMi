import Combine
import SwiftUI
import MapKit

class LocationSearchViewModel: ObservableObject {
    @Published var searchResults: [MKMapItem] = [] // 搜索結果
    @Published var searchQuery: String = "" {
        didSet {
            searchLocations()
        }
    }
    @Published var errorMessage: String? // 顯示錯誤訊息
    private var localSearch: MKLocalSearch?
    var locationManager: LocationManager?

    func searchLocations() {
        
        guard !searchQuery.isEmpty else {
            self.searchResults = []
            self.errorMessage = nil
            return
        }
        
        // 取消先前的搜索請求
        localSearch?.cancel()

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.resultTypes = [.pointOfInterest, .address] // 查詢地點或地址

        localSearch = MKLocalSearch(request: request)
        localSearch?.start { [weak self] (response, error) in
            if let error = error {
                print("搜尋失敗: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorMessage = "搜尋失敗，請稍後再試"
                }
                return
            }

            
            // 更新搜索結果
            if let mapItems = response?.mapItems {
                DispatchQueue.main.async {
                    self?.searchResults = mapItems
                    self?.errorMessage = nil
                }
            } else {
                // 如果沒有找到任何結果
                DispatchQueue.main.async {
                    self?.searchResults = []
                    self?.errorMessage = "沒有找到相關地點"
                }
            }
        }
    }
}
