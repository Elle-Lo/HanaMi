import SwiftUI
import FirebaseFirestore

struct CollectionsPage: View {
    @State private var favoriteTreasures: [Treasure] = []
    @State private var isLoading = true
    @State private var isEditing = false // 控制是否顯示編輯模式
    @State private var isPlayingAnimation = true // 控制動畫播放
    @Environment(\.presentationMode) var presentationMode
    private let firestoreService = FirestoreService()

    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }

    var body: some View {
        ZStack {
            Color(.colorYellow)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // 標題和編輯按鈕
                ZStack {
                    // 中間的標題
                    Text("Collection")
                        .foregroundColor(.colorBrown)
                        .font(.custom("LexendDeca-Bold", size: 30))

                    // 右上角的編輯按鈕
                    HStack {
                        Spacer()
                        Button(action: {
                            isEditing.toggle()
                        }) {
                            Text(isEditing ? "Done" : "Edit")
                                .foregroundColor(.colorBrown)
                        }
                    }
                    .padding(.trailing, 20) // 調整按鈕的右邊距離
                }
                .padding(.top, 10)

                if isLoading {
                    // Lottie 動畫替代 ProgressView
                    LottieView(animationFileName: "walking", loopMode: .loop, isPlaying: $isPlayingAnimation)
                        .frame(width: 140, height: 140)
                        .offset(y: 550)  // 調整動畫在按鈕上方的位置
                        .scaleEffect(0.3)  // 調整動畫大小
                        .onAppear {
                            isPlayingAnimation = true // 開始播放動畫
                        }
                        .onDisappear {
                            isPlayingAnimation = false // 停止動畫
                        }

                    Spacer()

                } else if favoriteTreasures.isEmpty {
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
                                HStack {
                                    CollectionTreasureCardView(treasure: treasure)

                                    if isEditing {
                                        Button(action: {
                                            removeTreasureFromFavorites(treasureID: treasure.id ?? "")
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                                .padding(10)
                                        }
                                    }
                                }
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.colorBrown)
                }
            }
        }
    }

    private func loadFavoriteTreasures() {
        print("Starting to load favorite treasures...")
        firestoreService.fetchFavoriteTreasures(userID: userID) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let treasures):
                    self.favoriteTreasures = treasures
                    print("Successfully fetched treasures: \(treasures.count) treasures found.")
                case .failure(let error):
                    print("Error fetching favorite treasures: \(error.localizedDescription)")
                }
            }
        }
    }

    private func removeTreasureFromFavorites(treasureID: String) {
        firestoreService.removeTreasureFromFavorites(userID: userID, treasureID: treasureID) { result in
            switch result {
            case .success:
                print("Successfully removed treasure with ID: \(treasureID)")
                loadFavoriteTreasures()
            case .failure(let error):
                print("Failed to remove treasure: \(error.localizedDescription)")
            }
        }
    }
}
