import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showCategory = true
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear

        // 使用 createGradientImage 函數來創建漸變圖像，並應用到 UITabBar 的背景
        if let gradientImage = createGradientImage(colors: [UIColor.colorDarkYellow, UIColor.white], size: CGSize(width: UIScreen.main.bounds.width, height: 50), opacity: 0.3) {
            appearance.backgroundImage = gradientImage  // 將漸變圖像作為背景
        }

        // 設置未選中項目的顏色
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.colorGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.colorGray]

        // 設置選中項目的顏色
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.brown
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.brown]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
    }
    
    func createGradientImage(colors: [UIColor], size: CGSize, opacity: CGFloat) -> UIImage? {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        gradientLayer.colors = colors.map { $0.withAlphaComponent(opacity).cgColor }

        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }

    var body: some View {
            TabView(selection: $selectedTab) {
                HomePage()
                    .tabItem {
                        Label("主頁", systemImage: "house.fill")
                    }
                    .tag(0)
                
                CategoryAndAnalyticsPage(showCategory: $showCategory)
                    .tabItem {
                        Label("類別", systemImage: "chart.pie")
                    }
                    .tag(1)
                
                DepositPage()
                    .tabItem {
                        Label("新增", systemImage: "plus.circle.fill")
                    }
                    .tag(2)

                TreasureMapPage(userID: userID)
                    .tabItem {
                        Label("地圖", systemImage: "mappin.and.ellipse")
                    }
                    .tag(3)

                CharacterPage()
                    .tabItem {
                        Label("角色", systemImage: "person.crop.circle.fill")
                    }
                    .tag(4)
            }
            
            .accentColor(.colorBrown) // 选中的 tab 项目变为黑色
            .background(
                Color.white.opacity(0.3) // 添加半透明的白色背景
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

    // 切換顯示 Category 或 Analytics 的按鈕
        var categoryAnalyticsToggleButton: some View {
            Button(action: {
                showCategory.toggle() // 切換頁面
            }) {
                Image(systemName: showCategory ? "chart.bar.xaxis" : "list.bullet")
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
    
    var backButton: some View {
            Button(action: {
                // 添加自定義返回邏輯，或使用默認返回
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.colorBrown)
            }
        }
}

#Preview {
    MainTabView()
}
