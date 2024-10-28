import SwiftUI
import FirebaseFirestore

struct AnalyticsView: View {
    @State private var categoryCounts: [String: Int] = [:]
    @State private var mostSavedCategory: String?
    @State private var mostSavedPercentage: Double = 0
    @State private var totalCount: Int = 0
    @State private var isLoading = true
    @State private var categories: [String] = []

    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    private let firestoreService = FirestoreService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
           
            Text("Analytics")
                .foregroundColor(.colorBrown)
                .font(.custom("LexendDeca-Bold", size: 30))
                .padding(.bottom, 50)

            if isLoading {
                ProgressView("加載中...")
            } else if let mostSaved = mostSavedCategory {
                VStack {

                    Circle()
                        .trim(from: 0.0, to: CGFloat(mostSavedPercentage))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .fill(Color(hex: "FFECC8"))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 180, height: 180)
                        .overlay(
                            Text(String(format: "%.0f%%", mostSavedPercentage * 100))
                                .font(.custom("LexendDeca-Bold", size: 30))
                                .foregroundColor(Color(hex: "FFECC8"))
                        )
                    .padding(.bottom, 30)
                    
                    Text("最常儲存的類別")
                        .font(.custom("LexendDeca-SemiBold", size: 13))
                        .foregroundColor(.gray)
                        .padding(.bottom, 1)

                    Text(mostSaved)
                        .font(.custom("LexendDeca-Bold", size: 20))
                        .foregroundColor(.colorBrown)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.colorYellow)
                        .cornerRadius(20)
                       
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
          
            Spacer().frame(height: 15)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(categories, id: \.self) { category in
                        if category != mostSavedCategory {
                            HStack {
                               
                                Text(category)
                                    .font(.custom("LexendDeca-Bold", size: 15))
                                    .foregroundColor(.gray)
                                    .frame(width: 110, alignment: .leading)

                                HStack(spacing: 10) {
                                    
                                    let percentage = totalCount > 0 ? CGFloat(categoryCounts[category, default: 0]) / CGFloat(totalCount) : 0
                                    
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color(hex: "FFECC8"))
                                        .frame(width: percentage * 200, height: 10)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.0f%%", percentage * 100))
                                        .font(.custom("LexendDeca-Bold", size: 15))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 25)
            }
            .padding(.horizontal, 10)
            .background(Color.colorYellow)
            .cornerRadius(15)
            .scrollIndicators(.hidden)

            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            fetchCategoryData()
        }
    }

    private func fetchCategoryData() {
        isLoading = true
        firestoreService.loadCategories(userID: userID) { fetchedCategories in
            self.categories = fetchedCategories

            firestoreService.fetchAllTreasures(userID: userID) { result in
                switch result {
                case .success(let treasures):
                  
                    var categoryCounts: [String: Int] = [:]
                    for category in fetchedCategories {
                        categoryCounts[category] = 0
                    }
                    for treasure in treasures {
                        categoryCounts[treasure.category, default: 0] += 1
                    }

                    self.categoryCounts = categoryCounts
                    self.totalCount = treasures.count

                    if let maxCategory = categoryCounts.max(by: { $0.value < $1.value })?.key {
                        self.mostSavedCategory = maxCategory
                        self.mostSavedPercentage = Double(categoryCounts[maxCategory] ?? 0) / Double(totalCount)
                    }

                    self.isLoading = false
                case .failure(let error):
                    print("加載寶藏失敗: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
}
