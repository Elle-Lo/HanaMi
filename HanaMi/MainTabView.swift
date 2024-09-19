import SwiftUI

struct MainTabView: View {
    private var userID: String = "g61HUemIJIRIC1wvvIqa"
    
    init() {
        // 修改选中的 tab 颜色
        UITabBar.appearance().barTintColor = UIColor.white.withAlphaComponent(0.7) // 半透明白色背景
        UITabBar.appearance().unselectedItemTintColor = UIColor.lightGray 
    }
    
    var body: some View {
        NavigationView {
            TabView {
                HomePage()
                    .tabItem {
                        Label("主頁", systemImage: "house.fill")
                    }

                CategoryAndAnalyticsPage()
                    .tabItem {
                        Label("類別分析", systemImage: "chart.pie")
                    }

                DepositPage()
                    .tabItem {
                        Label("儲存", systemImage: "plus.circle.fill")
                    }

                TreasureMapPage(userID: userID)
                    .tabItem {
                        Label("地圖", systemImage: "mappin.and.ellipse.circle.fill")
                    }

                CharacterPage()
                    .tabItem {
                        Label("角色", systemImage: "person.crop.circle.fill")
                    }
            }
            .accentColor(.black) // 选中的 tab 项目变为黑色
            .background(
                Color.white.opacity(0.7) // 添加半透明的白色背景
                    .edgesIgnoringSafeArea(.all)
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: settingsButton)
        }
    }

    var settingsButton: some View {
        NavigationLink(destination: SettingsPage()) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 40, height: 40) // 圆形背景
                        .opacity(0.3)
                )
        }
    }
}

#Preview {
    MainTabView()
}
