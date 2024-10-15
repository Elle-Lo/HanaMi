import SwiftUI

struct StatusSelectionSheet: View {
    
    @Binding var showSheet: Bool
    var currentNotification: CharacterAnimationScene
    var performActionAndUpdateStatus: (String) -> Void
    
    var body: some View {
        VStack {
            Text("角色狀態")
                .font(.headline)
                .padding()
                .foregroundColor(.brown)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ActionButton(title: "走路", action: {
                        currentNotification.performAction(named: "walk")
                        performActionAndUpdateStatus("walk")
                        showSheet = false
                    })
                    
                    ActionButton(title: "待機", action: {
                        currentNotification.performAction(named: "idle")
                        performActionAndUpdateStatus("idle")
                        showSheet = false
                    })
                    
                    ActionButton(title: "翻滾", action: {
                        currentNotification.performAction(named: "roll")
                        performActionAndUpdateStatus("roll")
                        showSheet = false
                    })
                    
                    ActionButton(title: "暈眩", action: {
                        currentNotification.performAction(named: "stuned")
                        performActionAndUpdateStatus("stuned")
                        showSheet = false
                    })
                    
                    ActionButton(title: "氣功", action: {
                        currentNotification.performAction(named: "throwing")
                        performActionAndUpdateStatus("throwing")
                        showSheet = false
                    })
                    
                    ActionButton(title: "跳躍", action: {
                        currentNotification.performAction(named: "jump")
                        performActionAndUpdateStatus("jump")
                        showSheet = false
                    })
                    
                    ActionButton(title: "魔法", action: {
                        currentNotification.performAction(named: "hit")
                        performActionAndUpdateStatus("hit")
                        showSheet = false
                    })
                    
                    ActionButton(title: "飛行", action: {
                        currentNotification.performAction(named: "fly")
                        performActionAndUpdateStatus("fly")
                        showSheet = false
                    })
                    
                    ActionButton(title: "暈倒", action: {
                        currentNotification.performAction(named: "dead")
                        performActionAndUpdateStatus("dead")
                        showSheet = false
                    })
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .padding(.bottom)
        .background(Color.clear) 
    }
}
