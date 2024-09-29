import SwiftUI
import Firebase

struct SettingsPage: View {
    @AppStorage("log_Status") private var logStatus: Bool = false
    
    var body: some View {
        VStack {
            Text("設定頁面")
                .font(.largeTitle)
                .padding()

            // 這裡可以添加各種設定選項
            Text("預計做登出和更換背景、和收藏")
                .padding()
            Button("Log Out") {
                try? Auth.auth().signOut()
                logStatus = false
            }
            Spacer()
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}
