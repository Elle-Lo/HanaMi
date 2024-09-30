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
        VStack(alignment: .leading, spacing: 20) {
            // 標題
            Text("ANALYTICS")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.brown)
                .padding(.top)

            // 副標題
            Text("最常儲存的類別")
                .font(.subheadline)
                .foregroundColor(.gray)

            // 最常儲存的類別與圓形圖表
            if isLoading {
                ProgressView("加載中...")
            } else if let mostSaved = mostSavedCategory {
                VStack {
                    Text(mostSaved)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.gray)

                    // 圓形圖表 - 顯示最多儲存類別的百分比
                    Circle()
                        .trim(from: 0.0, to: CGFloat(mostSavedPercentage))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .fill(Color.orange.opacity(0.3))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 180, height: 180)
                        .overlay(
                            Text(String(format: "%.0f%%", mostSavedPercentage * 100))
                                .font(.title)
                                .bold()
                                .foregroundColor(.orange)
                        )
                        .padding(.top, 10) // 圓形圖表與最常儲存類別之間的間距
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            // 加大其他類別與圓形的間距
            Spacer().frame(height: 20)

            // 顯示其他類別的比例，使用 ScrollView 以防放不下
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(categories, id: \.self) { category in
                        if category != mostSavedCategory {  // 排除最常儲存的類別
                            HStack {
                                Text(category)
                                    .font(.title3)  // 字體大小變大
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)

                                Spacer()

                                // 确保 totalCount 不为 0
                                let percentage = totalCount > 0 ? CGFloat(categoryCounts[category, default: 0]) / CGFloat(totalCount) : 0
                                
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.orange.opacity(0.2))
                                    .frame(width: percentage * 200, height: 10)  // 防止除以0的问题

                                Text(String(format: "%.0f%%", percentage * 100))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                        }
                    }
                }
            }
            .padding(.horizontal) 
            .scrollIndicators(.hidden)

            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            fetchCategoryData()
        }
    }

    // 從 Firestore 獲取類別寶藏數據
    private func fetchCategoryData() {
        isLoading = true
        firestoreService.loadCategories(userID: userID, defaultCategories: []) { fetchedCategories in
            self.categories = fetchedCategories  // 保存所有類別

            firestoreService.fetchAllTreasures(userID: userID) { result in
                switch result {
                case .success(let treasures):
                    // 計算各類別的寶藏數量
                    var categoryCounts: [String: Int] = [:]
                    for category in fetchedCategories {
                        categoryCounts[category] = 0  // 初始化所有類別的寶藏數量為 0
                    }
                    for treasure in treasures {
                        categoryCounts[treasure.category, default: 0] += 1
                    }

                    // 更新狀態
                    self.categoryCounts = categoryCounts
                    self.totalCount = treasures.count

                    // 找到寶藏數量最多的類別
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
