import SwiftUI
import MapKit

struct LocationSearchView: View {
    @ObservedObject var viewModel: LocationSearchViewModel
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedLocationName: String?
    @ObservedObject var locationManager: LocationManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TextField("輸入地點名稱", text: $viewModel.searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top)
            } else if viewModel.searchResults.isEmpty {
                Text("沒有結果")
                    .foregroundColor(.gray)
                    .padding(.top)
            }

            List(viewModel.searchResults, id: \.self) { result in
                Button(action: {
                    selectLocation(result)
                }) {
                    VStack(alignment: .leading) {
                        Text(result.name ?? "未知地點")
                        if let distance = calculateDistance(from: result.placemark.coordinate) {
                            Text("距離：\(String(format: "%.2f", distance)) 公里")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            Spacer()
        }
    }

    private func selectLocation(_ mapItem: MKMapItem) {
        selectedCoordinate = mapItem.placemark.coordinate
        selectedLocationName = mapItem.name ?? "未知地點"
        presentationMode.wrappedValue.dismiss()
    }

    private func calculateDistance(from coordinate: CLLocationCoordinate2D) -> Double? {
        guard let userLocation = locationManager.location else { return nil }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: userLocation) / 1000
    }
}
