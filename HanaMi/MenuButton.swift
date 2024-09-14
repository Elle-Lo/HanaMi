//
//  MenuButton.swift
//  HanaMi
//
//  Created by Tzu ning Lo on 2024/9/14.
//

import SwiftUI

struct MenuButton: View {
    @Binding var showMenu: Bool
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Button(action: {
                    withAnimation {
                        showMenu.toggle() // 切换菜单显示状态
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(showMenu ? Color.clear : Color.white.opacity(0.3))
                        .cornerRadius(showMenu ? 0 : 10)
                }
                .position(x: showMenu ? geometry.size.width / 2 : 55, y: showMenu ? 60 : 40)
                .animation(.easeInOut(duration: 0.4), value: showMenu) // 动画控制
            }
            .frame(height: 50)
        }
    }
}

