import SwiftUI

// 狀態選擇的 Sheet
struct StatusSelectionSheet: View {
    
    // 傳入的場景，用於控制動畫
    @Binding var showSheet: Bool  // 使用 @Binding 來控制 Sheet 的顯示與隱藏
    var currentNotification: CharacterAnimationScene
    var performActionAndUpdateStatus: (String) -> Void
    
    var body: some View {
        VStack {
            Text("角色狀態")
                .font(.headline)
                .padding()
                .foregroundColor(.brown)  // 顏色與圖片中的文字相符
            
            // 橫向滾動的 ScrollView，確保按鈕不被裁剪
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {  // 設置間距
                    ActionButton(title: "走路", action: {
                        currentNotification.performAction(named: "walk")
                        performActionAndUpdateStatus("walk")
                        showSheet = false  // 點擊後隱藏 Sheet
                    })
                    
                    ActionButton(title: "待機", action: {
                        currentNotification.performAction(named: "idle")
                        performActionAndUpdateStatus("idle")
                        showSheet = false  // 點擊後隱藏 Sheet
                    })
                    
                    ActionButton(title: "翻滾", action: {
                        currentNotification.performAction(named: "roll")
                        performActionAndUpdateStatus("roll")
                        showSheet = false  // 點擊後隱藏 Sheet
                    })
                    
                    ActionButton(title: "暈眩", action: {
                        currentNotification.performAction(named: "stuned")
                        performActionAndUpdateStatus("stuned")
                        showSheet = false  // 點擊後隱藏 Sheet
                    })
                    
                    ActionButton(title: "氣功", action: {
                        currentNotification.performAction(named: "throwing")
                        performActionAndUpdateStatus("throwing")
                        showSheet = false  // 點擊後隱藏 Sheet
                    })
                    
                    ActionButton(title: "跳躍", action: {
                        currentNotification.performAction(named: "jump")
                        performActionAndUpdateStatus("jump")
                        showSheet = false  // 點擊後隱藏 Sheet
                    })
                    
                    ActionButton(title: "魔法", action: {
                        currentNotification.performAction(named: "hit")
                        performActionAndUpdateStatus("hit")
                        showSheet = false  // 點擊後隱藏 Sheet
                    })
                    
                    ActionButton(title: "飛行", action: {
                        currentNotification.performAction(named: "fly")
                        performActionAndUpdateStatus("fly")
                        showSheet = false  // 點擊後隱藏 Sheet
                    })
                    
                    ActionButton(title: "暈倒", action: {
                        currentNotification.performAction(named: "dead")
                        performActionAndUpdateStatus("dead")
                        showSheet = false  // 點擊後隱藏 Sheet
                    })
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            /*.frame(height: 80) */ // 控制 ScrollView 的高度，避免按鈕被裁剪
        }
        .padding(.bottom)  // 保持和頁面底部的距離
        .background(Color.clear)  // 半透明白色背景
    }
}
