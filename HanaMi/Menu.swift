import SwiftUI

struct Menu: View {
    @Binding var showMenu: Bool
    @State private var showHome = false // 控制是否显示 Home 页面
    @State private var showDeposit = false
    @State private var showCategory = false
    @State private var showAnalytics = false
    @State private var showTreasureMap = false
    @State private var showCharacterPage = false

    var body: some View {
        ZStack {
            // 背景色，使用两个颜色叠加
            Color(hex: "6C6C6C").opacity(0.75)
                .overlay(Color(hex: "FFF7EF").opacity(0.55))
                .edgesIgnoringSafeArea(.all)

            // 菜单内容
            VStack(alignment: .center, spacing: 20) {
                // 点击 Home 显示 Home 页面
                Button(action: {
                    withAnimation {
                        showHome.toggle() // 打开 Home 页面
                    }
                }) {
                    Text("HOME")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.bottom, 50)
                }
                .fullScreenCover(isPresented: $showHome) {
                    HomePage() // 全屏显示 HomePage
                }

                VStack(spacing: 30) {
                    // 其他页面
                    Button(action: {
                        showDeposit.toggle()
                    }) {
                        Text("Deposit")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .fullScreenCover(isPresented: $showDeposit) {
                        DepositPage()
                    }

                    Button(action: {
                        showCategory.toggle()
                    }) {
                        Text("Category")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .fullScreenCover(isPresented: $showCategory) {
                        CategoryPage()
                    }

                    Button(action: {
                        showAnalytics.toggle()
                    }) {
                        Text("Analytics")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .fullScreenCover(isPresented: $showAnalytics) {
                        AnalyticsPage()
                    }

                    Button(action: {
                        showTreasureMap.toggle()
                    }) {
                        Text("Treasure Map")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .fullScreenCover(isPresented: $showTreasureMap) {
                        TreasureMapPage()
                    }

                    Button(action: {
                        showCharacterPage.toggle()
                    }) {
                        Text("Hey It's Me")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .fullScreenCover(isPresented: $showCharacterPage) {
                        CharacterPage()
                    }
                }

                Spacer()
            }
            .padding(.top, 100)
        }
    }
}
