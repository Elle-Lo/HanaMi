import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showCategory = true
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    init() {
        // 修改选中的 tab 颜色
        UITabBar.appearance().barTintColor = UIColor.white.withAlphaComponent(0.7) // 半透明白色背景
        UITabBar.appearance().unselectedItemTintColor = UIColor.lightGray
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                HomePage()
                    .tabItem {
                        Label("主頁", systemImage: "house.fill")
                    }
                    .tag(0)
                
                CategoryAndAnalyticsPage(showCategory: $showCategory)
                    .tabItem {
                        Label("類別分析", systemImage: "chart.pie")
                    }
                    .tag(1)
                
                DepositPage()
                    .tabItem {
                        Label("儲存", systemImage: "plus.circle.fill")
                    }
                    .tag(2)

                TreasureMapPage(userID: userID)
                    .tabItem {
                        Label("地圖", systemImage: "mappin.and.ellipse.circle.fill")
                    }
                    .tag(3)

                CharacterPage()
                    .tabItem {
                        Label("角色", systemImage: "person.crop.circle.fill")
                    }
                    .tag(4)
            }
            
            .accentColor(.black) // 选中的 tab 项目变为黑色
            .background(
                Color.white.opacity(0.7) // 添加半透明的白色背景
                    .edgesIgnoringSafeArea(.all)
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: HStack {
                if selectedTab == 1 { // 只在CategoryAndAnalyticsPage中顯示切換按鈕
                    categoryAnalyticsToggleButton
                }
                settingsButton // 全局設定按鈕
            })
        }
    }

    // 切換顯示 Category 或 Analytics 的按鈕
        var categoryAnalyticsToggleButton: some View {
            Button(action: {
                showCategory.toggle() // 切換頁面
            }) {
                Image(systemName: showCategory ? "chart.bar.fill" : "list.bullet")
                    .resizable()
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 40, height: 40)
                            .cornerRadius(10)
                            .opacity(0.3)
                    )
            }
            .padding(.trailing, 5)
        }
    
    // 全局的設定按鈕
    var settingsButton: some View {
        NavigationLink(destination: SettingsPage()) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 40, height: 40)
                        .cornerRadius(10)
                        .opacity(0.3)
                )
        }
    }
}

#Preview {
    MainTabView()
}
