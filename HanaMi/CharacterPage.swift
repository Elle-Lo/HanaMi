//
//  CharacterPage.swift
//  HanaMi
//
//  Created by Tzu ning Lo on 2024/9/14.
//

import SwiftUI

struct CharacterPage: View {
    @State private var showMenu = false

       var body: some View {
           ZStack {
                       
                       Color.green.edgesIgnoringSafeArea(.all) 

                       // 页面内容
                       VStack {
                           Spacer()
                           Text("This is Character Page")
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
    CharacterPage()
}
