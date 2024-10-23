//
//  MusicSearchView.swift
//  HanaMi
//
//  Created by Tzu ning Lo on 2024/10/23.
//

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
                    // 每當輸入內容改變時觸發搜尋
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
    
    // 使用 MusicKit 搜尋音樂
    func searchMusic() {
        guard !searchTerm.isEmpty else { return }  // 確保搜尋字串非空
        
        let request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
        Task {
            do {
                let response = try await request.response()
                if let songs = response.songs {
                    musicResults = songs.items  // 確保解包 items
                } else {
                    musicResults = []  // 如果沒有歌曲，設置為空
                }
            } catch {
                print("搜尋失敗: \(error)")
            }
        }
    }
}
