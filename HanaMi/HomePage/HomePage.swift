import SwiftUI
import FirebaseFirestore
import Kingfisher
import AVFoundation
import FirebaseCrashlytics

struct HomePage: View {
    @State private var treasures: [Treasure] = []
    @State private var isLoading = false
    @State private var selectedBackgroundImage: UIImage?
    @State private var isUsingDefaultBackground = true
    @State private var backgroundImageUrl: URL?
    
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    private let firestoreService = FirestoreService()
    
    var body: some View {
        ZStack {
            
            Color.black.opacity(0.2).edgesIgnoringSafeArea(.all)
            
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                } else {
                    ScrollView {
                        ForEach(treasures) { treasure in
                            TreasureCardView(treasure: treasure)
                                .padding(.top, 30)
                        }
                    }
                    .padding(.horizontal, 30)
                    .scrollIndicators(.hidden)
                }
                
                Spacer()
            }
            
            VStack {
                Spacer()

                HStack {
                    Spacer()
                    Button(action: {
                        fetchRandomTreasures()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.gray).frame(width: 50, height: 50).opacity(0.3))
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 70)
                }
            }
        }
        .background(
            Group {
                if let backgroundImageUrl = backgroundImageUrl, !isUsingDefaultBackground {
                    KFImage(backgroundImageUrl)
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Image("Homebg")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                }
            }
        )
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            fetchBackgroundImage()
            fetchRandomTreasures()
        }
    }
    
    func fetchBackgroundImage() {
        firestoreService.fetchUserBackgroundImage(uid: userID) { imageUrlString in
            if let imageUrlString = imageUrlString, let url = URL(string: imageUrlString) {
                self.backgroundImageUrl = url
                self.isUsingDefaultBackground = false
            } else {
                self.isUsingDefaultBackground = true  
            }
        }
    }
    
    func fetchRandomTreasures() {
        isLoading = true
        firestoreService.fetchRandomTreasures(userID: userID) { result in
            switch result {
            case .success(let fetchedTreasures):
                treasures = fetchedTreasures
            case .failure(let error):
                print("獲取寶藏失敗: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}
