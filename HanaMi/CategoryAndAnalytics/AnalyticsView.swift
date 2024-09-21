import SwiftUI
import FirebaseFirestore

struct AnalyticsView: View {
    @State private var categoryCounts: [String: Int] = [:]
    @State private var mostSavedCategory: String?
    @State private var mostSavedPercentage: Double = 0
    @State private var totalCount: Int = 0
    @State private var isLoading = true
    @State private var categories: [String] = []

    private let userID = "g61HUemIJIRIC1wvvIqa"
    private let firestoreService = FirestoreService()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                        .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            // 下方顯示其他類別的比例
            VStack(alignment: .leading, spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    if category != mostSavedCategory {  // 排除最常儲存的類別
                        HStack {
                            Text(category)
                                .font(.subheadline)
                                .foregroundColor(.black)

                            Spacer()

                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: calculateBarWidth(for: category), height: 10)

                            Text(String(format: "%.0f%%", calculatePercentage(for: category) * 100))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(.horizontal)  // 增加左右間距

            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            fetchCategoryData()
        }
    }

    // 計算條狀圖的寬度
    private func calculateBarWidth(for category: String) -> CGFloat {
        guard totalCount > 0 else { return 0 }  // 確保總數不為 0
        return CGFloat(categoryCounts[category, default: 0]) / CGFloat(totalCount) * 200
    }

    // 計算類別的百分比
    private func calculatePercentage(for category: String) -> Double {
        guard totalCount > 0 else { return 0 }  // 確保總數不為 0
        return Double(categoryCounts[category, default: 0]) / Double(totalCount)
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
