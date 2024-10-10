import SwiftUI
import FirebaseFirestore

struct CollectionsPage: View {
    @State private var favoriteTreasures: [Treasure] = []
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode
    private let firestoreService = FirestoreService()

    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }

    var body: some View {
        ZStack {
            Color(.colorYellow)
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .center) {
                // 標題
                Text("Collection")
                    .foregroundColor(.colorBrown)
                    .font(.custom("LexendDeca-Bold", size: 30))

                // 卡片列表
                if isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .padding(.top, 50)
                    
                    Spacer()

                } else if favoriteTreasures.isEmpty {
                    // 顯示 "No collection" 當寶藏列表為空時
                    Text("No collection")
                        .foregroundColor(.gray)
                        .font(.custom("LexendDeca-Regular", size: 18))
                        .padding(.top, 50)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()

                } else {
                        ScrollView {
                            LazyVStack {
                                ForEach(favoriteTreasures, id: \.id) { treasure in
                                    CollectionTreasureCardView(treasure: treasure)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 10)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .scrollIndicators(.hidden)
                    }
                }
                    .onAppear {
                        loadFavoriteTreasures()
                    }
            }
        .navigationBarBackButtonHidden(true)  // 隱藏系統默認的返回按鈕
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()  // 返回到上一頁
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.colorBrown)
                }
            }
        }
    }

    // 初次加載收藏寶藏
    private func loadFavoriteTreasures() {
            print("Starting to load favorite treasures...")
            FirestoreService().fetchFavoriteTreasures(userID: userID) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success(let treasures):
                        self.favoriteTreasures = treasures
                        print("Successfully fetched treasures: \(treasures.count) treasures found.")
                        if treasures.isEmpty {
                            print("No favorite treasures found.")
                        } else {
                            for treasure in treasures {
                                print("Treasure found: \(treasure.id ?? "Unknown ID") - Category: \(treasure.category)")
                            }
                        }
                    case .failure(let error):
                        print("Error fetching favorite treasures: \(error.localizedDescription)")
                    }
                }
            }
        }
}
