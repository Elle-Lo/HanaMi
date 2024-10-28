import SwiftUI

struct CategoryAndAnalyticsPage: View {
    @Binding var showCategory: Bool

    var body: some View {
        VStack {
           
            if showCategory {
                CategoryView()
            } else {
                AnalyticsView()
            }
        }
        .navigationTitle(showCategory ? "Category" : "Analytics")
        .navigationBarTitleDisplayMode(.inline) 
    }
}
