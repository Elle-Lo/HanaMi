//
//  AnalyticsPage.swift
//  HanaMi
//
//  Created by Tzu ning Lo on 2024/9/14.
//

import SwiftUI

struct AnalyticsPage: View {
    @State private var showMenu = false

       var body: some View {
           ZStack {
                       // 背景图像
                       Color.green.edgesIgnoringSafeArea(.all) // 背景为绿色

                       // 页面内容
                       VStack {
                           Spacer()
                           Text("This is Analytics Page")
                               .font(.largeTitle)
                               .foregroundColor(.white)
                           Spacer()
                       }

                       // 放置菜单按钮
                       MenuButton(showMenu: $showMenu)
                           .zIndex(2) // 确保按钮在页面最上层
                       
                       // 自定义菜单动画显示，避免使用 fullScreenCover
                       if showMenu {
                           Menu(showMenu: $showMenu)
                               .transition(.move(edge: .leading)) // 自定义过渡效果
                               .animation(.easeInOut, value: showMenu)
                               .zIndex(1) // 保证菜单在内容上方
                       }
                   }
               }
           }

#Preview {
    AnalyticsPage()
}
