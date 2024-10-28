import SwiftUI
import MapKit

enum ActiveSheet: Identifiable {
    case map, search
    
    var id: ActiveSheet { self }
}

struct LocationSelectionView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedLocationName: String?
    @Binding var shouldZoomToUserLocation: Bool
    @ObservedObject var locationManager: LocationManager
    
    @ObservedObject var searchViewModel: LocationSearchViewModel
    @State private var activeSheet: ActiveSheet?
    let userID: String
    
    var body: some View {
        HStack {
            
            Button(action: {
                activeSheet = .search
            }) {
                Image(systemName: "magnifyingglass")
                    .padding(10)
                    .background(Color(hex: "#E0E0E0"))
                    .cornerRadius(10)
            }
            .padding(.trailing, 2)
           
            Button(action: {
                shouldZoomToUserLocation = true
                activeSheet = .map
            }) {
                HStack {
              
                    if let name = selectedLocationName {
                        HStack {
                            Image("pin")
                                .resizable()
                                .frame(width: 15, height: 15)
                                .foregroundColor(.colorBrown)
                            
                            Text("\(name)")
                                .foregroundColor(.colorBrown)
                                .font(.custom("LexendDeca-SemiBold", size: 13))
                        }
                        .padding(.vertical, 11)
                        .padding(.trailing, 19)
                        .padding(.leading, 13)
                        .background(Color(hex: "#E0E0E0"))
                        .cornerRadius(10)
                    } else {
                        HStack {
                            Image("pin")
                                .resizable()
                                .frame(width: 15, height: 15)
                                .foregroundColor(.colorBrown)
                            
                            Text("選擇地點")
                                .foregroundColor(.colorBrown)
                                .font(.custom("LexendDeca-SemiBold", size: 13))
                        }
                        .padding(.vertical, 11)
                        .padding(.trailing, 19)
                        .padding(.leading, 13)
                        .background(Color(hex: "#E0E0E0"))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(item: $activeSheet) { item in
            switch item {
            case .map:
                VStack {
                    
                    CustomMapView(
                        selectedCoordinate: $selectedCoordinate,
                        selectedLocationName: $selectedLocationName,
                        shouldZoomToUserLocation: $shouldZoomToUserLocation,
                        selectedTreasure: .constant(nil),
                        showTreasureDetail: .constant(false),
                        isShowingAllTreasures: .constant(false),
                        locationManager: locationManager,
                        treasureManager: TreasureManager(), 
                        mode: .selectLocation,
                        userID: userID
                    )
                    .edgesIgnoringSafeArea(.all)
                }
                .presentationDetents([.height(650), .large])
                .presentationDragIndicator(.visible)
                
            case .search:
                LocationSearchView(
                    viewModel: searchViewModel,
                    selectedCoordinate: $selectedCoordinate,
                    selectedLocationName: $selectedLocationName,
                    locationManager: locationManager
                )
            }
        }
    }
}
