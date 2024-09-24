import SwiftUI
import FirebaseFirestore
import Kingfisher

struct HomePage: View {
    @State private var treasures: [Treasure] = []
    @State private var isLoading = false

    private let userId = "g61HUemIJIRIC1wvvIqa"
    private let firestoreService = FirestoreService()

    var body: some View {
        NavigationView {
            ZStack {
                // 背景圖片
                Image("Homebg")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                // 半透明黑色遮罩
                Color.black.opacity(0.2).edgesIgnoringSafeArea(.all)

                VStack {
                    if isLoading {
                        ProgressView("加載中...")
                    } else {
                        ScrollView {
                            ForEach(treasures) { treasure in
                                TreasureCardView(treasure: treasure)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                        }
                        .scrollIndicators(.hidden)
                    }

                    Spacer()
                }
                .padding(.top, 15)

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
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            fetchRandomTreasures()
        }
    }

    func fetchRandomTreasures() {
        isLoading = true
        firestoreService.fetchRandomTreasures(userID: userId) { result in
            switch result {
            case .success(let fetchedTreasures):
                treasures = fetchedTreasures
            case .failure(let error):
                print("获取宝藏失败: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}


struct TreasureCardView: View {
    var treasure: Treasure

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
         
            Text(treasure.category)
                .font(.headline)
                .foregroundColor(.black)
                 .padding(.top, 10)

            Text("地點: \(treasure.locationName)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Divider()
                .padding(.vertical, 5)

            ForEach(treasure.contents.sorted(by: { $0.index < $1.index })) { content in
                VStack(alignment: .leading, spacing: 10) {
                   
                    switch content.type {
                    case .text:
                     
                        Text(content.content)
                            .font(.body)
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true) // 确保文本换行时不会拉伸

                    case .image:
                      
                        if let imageURL = URL(string: content.content) {
                            KFImage(imageURL)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(10)
                        }

                    case .link:
                       
                        if let url = URL(string: content.content) {
                            Text(content.displayText ?? url.absoluteString)
                                .font(.body)
                                .foregroundColor(.blue)
                                .underline()
                                .onTapGesture {
                                    UIApplication.shared.open(url)
                                }
                        }

                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, 5)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

