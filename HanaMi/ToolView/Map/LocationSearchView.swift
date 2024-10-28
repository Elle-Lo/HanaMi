import SwiftUI
import MapKit

struct LocationSearchView: View {
    @ObservedObject var viewModel: LocationSearchViewModel
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedLocationName: String?
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
          
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 10)
                
                TextField("就在這～", text: $viewModel.searchQuery)
                    .padding(.vertical, 12)
            }
            .background(Color.white)
            .cornerRadius(8)
            .padding(.top, 20)
            .padding(.horizontal, 16)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.gray)
                    .padding(.top)
                    .padding(.horizontal, 16)
            } else if viewModel.searchResults.isEmpty {
                Text("請輸入寶藏地點")
                    .foregroundColor(.gray)
                    .padding(.top)
                    .padding(.horizontal, 16)
            }
       
            List(viewModel.searchResults, id: \.self) { result in
                Button(action: {
                    selectLocation(result)
                }) {
                    VStack(alignment: .leading) {
                        Text(result.name ?? "未知地點")
                            .foregroundColor(.black)
                            .font(.custom("LexendDeca-SemiBold", size: 17))
                            .padding(.bottom, 5)
                        
                        if let distance = calculateDistance(from: result.placemark.coordinate) {
                            Text("距離：\(String(format: "%.2f", distance)) 公里")
                                .font(.custom("LexendDeca-SemiBold", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(PlainListStyle())
            .padding(.horizontal, 16)
            .background(Color.white)
            
            Spacer()
        }
        .background(Color.white)
        .ignoresSafeArea()
    }

private func selectLocation(_ mapItem: MKMapItem) {
    selectedCoordinate = mapItem.placemark.coordinate
    selectedLocationName = mapItem.name ?? "未知地點"
    dismiss()
}

private func calculateDistance(from coordinate: CLLocationCoordinate2D) -> Double? {
    guard let userLocation = locationManager.location else { return nil }
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    return location.distance(from: userLocation) / 1000
}
}
