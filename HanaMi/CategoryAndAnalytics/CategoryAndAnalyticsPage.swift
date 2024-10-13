import SwiftUI

struct CategoryAndAnalyticsPage: View {
    @Binding var showCategory: Bool // 預設顯示Category頁面

    var body: some View {
        VStack {
            // 切換顯示Category或Analytics
            if showCategory {
                CategoryView() // 顯示類別頁面
            } else {
                AnalyticsView() // 顯示分析頁面
            }
        }
        .navigationTitle(showCategory ? "Category" : "Analytics")
        .navigationBarTitleDisplayMode(.inline) // 只保留標題和頁面顯示邏輯
    }
}
