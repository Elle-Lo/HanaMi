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

        if let gradientImage = createGradientImage(colors: [UIColor.colorDarkYellow, UIColor.white], size: CGSize(width: UIScreen.main.bounds.width, height: 50), opacity: 0.3) {
            appearance.backgroundImage = gradientImage
        }

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.colorGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.colorGray]

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
                    .accessibilityIdentifier("MapTab")

                CharacterPage()
                    .tabItem {
                        Label("角色", systemImage: "person.crop.circle.fill")
                    }
                    .tag(4)
            }
            
            .accentColor(.colorBrown)
            .background(
                Color.white.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: HStack {
                if selectedTab == 1 {
                    categoryAnalyticsToggleButton
                }
                settingsButton
            })
    }

        var categoryAnalyticsToggleButton: some View {
            Button(action: {
                showCategory.toggle()
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
               
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.colorBrown)
            }
        }
}

#Preview {
    MainTabView()
}
