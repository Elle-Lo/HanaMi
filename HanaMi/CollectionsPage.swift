import SwiftUI
import FirebaseFirestore

struct CollectionsPage: View {
    @State private var favoriteTreasures: [Treasure] = []
    @State private var isLoading = true
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    var body: some View {
        ZStack {
            Color(.colorYellow)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading) {
                // 標題
                Text("Collection")
                    .foregroundColor(.colorBrown)
                    .font(.custom("LexendDeca-Bold", size: 30))
                    .padding(.leading, 20)
                
                // 卡片列表
                if isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .padding(.top, 50)
                } else {
                    ScrollView {
                        ForEach(favoriteTreasures, id: \.id) { treasure in
                            CollectionTreasureCardView(treasure: treasure)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .onAppear {
                loadFavoriteTreasures()
            }
        }
    }
    
    // 加載使用者的收藏寶藏
    private func loadFavoriteTreasures() {
        FirestoreService().fetchFavoriteTreasures(userID: userID) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let treasures):
                    self.favoriteTreasures = treasures
                case .failure(let error):
                    print("Error fetching favorite treasures: \(error.localizedDescription)")
                }
            }
        }
    }
}
