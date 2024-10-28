import SwiftUI
import MapKit

struct MapBounds {
    let minLat: Double
    let maxLat: Double
    let minLng: Double
    let maxLng: Double
}

struct TreasureFetcher {
    let locationManager: LocationManager
    let treasureManager: TreasureManager
    let isShowingAllTreasures: Bool
    
    func fetchTreasuresForCurrentBounds() {
        guard let location = locationManager.location else { return }
        
        let bounds = calculateRegionBounds(from: location)
        
        if isShowingAllTreasures {
            fetchPublicAndUserTreasuresInBounds(bounds)
        } else {
            fetchUserTreasuresInBounds(bounds)
        }
    }
    
    private func calculateRegionBounds(from location: CLLocation) -> MapBounds {
        let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLng = region.center.longitude - region.span.longitudeDelta / 2
        let maxLng = region.center.longitude + region.span.longitudeDelta / 2
        
        return MapBounds(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng)
    }
    
    private func fetchPublicAndUserTreasuresInBounds(_ bounds: MapBounds) {
        treasureManager.fetchAllPublicAndUserTreasures(minLat: bounds.minLat, maxLat: bounds.maxLat, minLng: bounds.minLng, maxLng: bounds.maxLng) { treasures in
            treasureManager.displayedTreasures = treasures
        }
    }
    
    private func fetchUserTreasuresInBounds(_ bounds: MapBounds) {
        treasureManager.fetchUserTreasures(minLat: bounds.minLat, maxLat: bounds.maxLat, minLng: bounds.minLng, maxLng: bounds.maxLng) { treasures in
            treasureManager.displayedTreasures = treasures
        }
    }
}

struct TreasureMapPage: View {
    
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var shouldZoomToUserLocation = true
    @State private var showTreasureDetail = false
    @State private var selectedTreasure: Treasure?
    @State private var isShowingAllTreasures = true
    
    @ObservedObject var locationManager = LocationManager()
    @ObservedObject var treasureManager = TreasureManager()
    
    let userID: String
    
    var body: some View {
        ZStack {
            CustomMapView(
                selectedCoordinate: $selectedCoordinate,
                selectedLocationName: $selectedLocationName,
                shouldZoomToUserLocation: $shouldZoomToUserLocation,
                selectedTreasure: $selectedTreasure,
                showTreasureDetail: $showTreasureDetail,
                isShowingAllTreasures: $isShowingAllTreasures,
                locationManager: locationManager,
                treasureManager: treasureManager,
                mode: .viewTreasures,
                userID: userID
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                HStack(spacing: 5) {
                    Button(action: {
                        isShowingAllTreasures = true
                        fetchTreasures()
                    }) {
                        Image(systemName: "globe.asia.australia.fill")
                            .font(.system(size: 18))
                            .foregroundColor(isShowingAllTreasures ? .colorBrown : .colorBrown)
                            .frame(width: 50, height: 40)
                            .background(isShowingAllTreasures ? Color.white : Color.clear)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 8)
                    
                    Button(action: {
                        isShowingAllTreasures = false
                        fetchTreasures()
                    }) {
                        Image(systemName: "figure.wave")
                            .font(.system(size: 22))
                            .foregroundColor(!isShowingAllTreasures ? .colorBrown : .colorBrown)
                            .frame(width: 50, height: 40)
                            .background(!isShowingAllTreasures ? Color.white : Color.clear)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 3)
                .background(Color(hex: "FCEEDF"))
                .clipShape(Capsule())
                .shadow(radius: 5)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showTreasureDetail) {
            if let treasure = selectedTreasure {
                TreasureDetailView(treasure: treasure)
            }
        }
        .onAppear {
            shouldZoomToUserLocation = true
            fetchTreasures()
        }
    }
    
    func fetchTreasures() {
        let fetcher = TreasureFetcher(
            locationManager: locationManager,
            treasureManager: treasureManager,
            isShowingAllTreasures: isShowingAllTreasures
        )
        fetcher.fetchTreasuresForCurrentBounds()
    }
}
