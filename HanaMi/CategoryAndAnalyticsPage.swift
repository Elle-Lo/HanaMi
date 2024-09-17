import SwiftUI

struct CategoryAndAnalyticsPage: View {
    var body: some View {
        VStack {
            Text("類別分析頁面")
                .font(.largeTitle)
                .padding()

            // 這裡可以添加各種設定選項
            Text("在這裡添加各種設定選項")
                .padding()

            Spacer()
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
           }

#Preview {
    CategoryAndAnalyticsPage()
}
