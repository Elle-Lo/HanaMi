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
            // 標題
            Text("Analytics")
                .foregroundColor(.colorBrown)
                .font(.custom("LexendDeca-Bold", size: 30))
                .padding(.bottom, 50)
            // 副標題
//            Text("最常儲存的類別")
//                .font(.custom("LexendDeca-Bold", size: 15))
//                .foregroundColor(.gray)
//                .padding(.bottom, 50)

            // 最常儲存的類別與圓形圖表
            if isLoading {
                ProgressView("加載中...")
            } else if let mostSaved = mostSavedCategory {
                VStack {

                    // 圓形圖表 - 顯示最多儲存類別的百分比
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
                    .padding(.bottom, 30) // 圓形圖表與最常儲存類別之間的間距
                    
                    Text("最常儲存的類別")
                        .font(.custom("LexendDeca-SemiBold", size: 15))
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
            // 加大其他類別與圓形的間距
            Spacer().frame(height: 20)

            // 顯示其他類別的比例，使用 ScrollView 以防放不下
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(categories, id: \.self) { category in
                        if category != mostSavedCategory {  // 排除最常儲存的類別
                            HStack {
                                // 類別名稱
                                Text(category)
                                    .font(.custom("LexendDeca-Bold", size: 15))
                                    .foregroundColor(.gray)
                                    .frame(width: 110, alignment: .leading) // 限制類別名稱寬度，確保統一對齊

                                // 進度條和百分比包在一起
                                HStack(spacing: 10) {
                                    // 設定進度條和百分比之間的間距
                                    // 确保 totalCount 不为 0
                                    let percentage = totalCount > 0 ? CGFloat(categoryCounts[category, default: 0]) / CGFloat(totalCount) : 0
                                    
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color(hex: "FFECC8"))
                                        .frame(width: percentage * 200, height: 10)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.0f%%", percentage * 100))
                                        .font(.custom("LexendDeca-Bold", size: 15))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading) // 確保進度條和百分比的對齊一致
                            }
                            
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .scrollIndicators(.hidden)

            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            fetchCategoryData()
        }
    }

    // 從 Firestore 獲取類別寶藏數據
    private func fetchCategoryData() {
        isLoading = true
        firestoreService.loadCategories(userID: userID) { fetchedCategories in
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
