import SwiftUI
import MusicKit

struct MusicSearchView: View {
    @Binding var searchTerm: String
    @Binding var musicResults: [Song]
    var onMusicSelected: (Song) -> Void
    
    var body: some View {
        VStack {
            TextField("搜尋音樂", text: $searchTerm)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: searchTerm) { newTerm in
                  
                    searchMusic()
                }
            
            if musicResults.isEmpty {
                Text("沒有結果").foregroundColor(.gray)
            } else {
                List(musicResults, id: \.id) { song in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(song.title)
                            Text(song.artistName)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            onMusicSelected(song)
                        }) {
                            Text("選擇")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }

    func searchMusic() {
        let request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
        Task {
            do {
                let response = try await request.response()
                musicResults = response.songs.compactMap { $0 }
            } catch {
                print("Error searching music: \(error)")
            }
        }
    }
}
