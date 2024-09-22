import SwiftUI

// 状态选择的 Sheet
struct StatusSelectionSheet: View {
    
    // 绑定到主视图的场景，控制动画
    @Binding var currentNotification: CharacterAnimationScene
    
    var body: some View {
        VStack {
            Text("選擇角色狀態")
                .font(.headline)
                .padding()
            
            // 状态按钮列表
            VStack(spacing: 20) {
                ActionButton(title: "走路", action: {
                    currentNotification.performAction(named: "walk")
                })
                
                ActionButton(title: "翻滾", action: {
                    currentNotification.performAction(named: "roll")
                })
                
                ActionButton(title: "暈眩", action: {
                    currentNotification.performAction(named: "stuned")
                })
                
                ActionButton(title: "投擲", action: {
                    currentNotification.performAction(named: "throwing")
                })
                
                ActionButton(title: "跳躍", action: {
                    currentNotification.performAction(named: "jump")
                })
            }
            .padding(.horizontal, 20)
        }
    }
}

