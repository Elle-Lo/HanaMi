import SwiftUI
import SpriteKit

struct CharacterPage: View {
    
    @State private var scene = CharacterAnimationScene(size: UIScreen.main.bounds.size)  // 创建场景实例

    var body: some View {
        ZStack {
            // 背景图片
            Image("Homebg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()  // 背景填充整个屏幕
            
            // SpriteKitView 透明背景
            SpriteKitView(scene: scene)
                .ignoresSafeArea()   // 让角色的场景填充整个页面
            
            VStack {
                Spacer()
                
                // 底部的按钮区域
                HStack {
                    Button(action: {
                        scene.performAction(named: "walk")  // 切换到走路动作
                    }) {
                        Text("走路")
                            .font(.body)
                            .bold()
                            .foregroundColor(.brown)
                            .frame(width: 80, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(radius: 3)
                            )
                    }
                    
                    Button(action: {
                        scene.performAction(named: "roll")  // 切换到翻滚动作
                    }) {
                        Text("翻滚")
                            .font(.body)
                            .bold()
                            .foregroundColor(.brown)
                            .frame(width: 80, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(radius: 3)
                            )
                    }
                    
                    Button(action: {
                        scene.performAction(named: "stuned")  // 切换到晕眩动作
                    }) {
                        Text("晕眩")
                            .font(.body)
                            .bold()
                            .foregroundColor(.brown)
                            .frame(width: 80, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(radius: 3)
                            )
                    }
                }
                .padding(.bottom, 30)  // 底部按钮的间距
            }
        }
        .onAppear {
            scene.scaleMode = .resizeFill
        }
    }
}


#Preview {
    CharacterPage()
}
