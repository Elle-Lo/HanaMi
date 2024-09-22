import SwiftUI
import SpriteKit

// 角色頁面主結構
struct CharacterPage: View {
    
    @State private var scene = CharacterAnimationScene(size: UIScreen.main.bounds.size)  // 創建場景實例
    @State private var showSheet = false  // 控制狀態 Sheet 顯示
    @State private var currentStatusText = "葉子帶著寶藏回來喔～"  // 初始狀態欄文字
    let statusMessages = ["喵咪睡著了", "葉子帶著寶藏回來喔～", "風兒輕輕吹", "狗狗在看書"]  // 寫死的狀態文字
    
    var body: some View {
        ZStack {
            // 背景圖片
            Image("Homebg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()  // 背景填充整個屏幕
            
            // SpriteKitView 透明背景
            SpriteKitView(scene: scene)
                .ignoresSafeArea()   // 讓角色的場景填充整個頁面
            
            VStack {
                // 加長的通知欄
                Text(currentStatusText)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 25)  // 圓角
                            .fill(Color.white.opacity(0.6))  // 半透明白色背景
                            .shadow(radius: 5)  // 添加陰影效果
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 30)  // 調整到頂部
                
                Spacer()
                
                // 底部按鈕區域
                HStack {
                    Button(action: {
                        showSheet = true  // 顯示狀態選擇 Sheet
                    }) {
                        Text("狀態")
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
                .padding(.bottom, 30)  // 底部按鈕的間距
            }
        }
        .onAppear {
            scene.scaleMode = .resizeFill
            loadInitialStatusText()  // 在載入時只更新一次狀態文字
        }
        .sheet(isPresented: $showSheet) {
            StatusSelectionSheet(showSheet: $showSheet, currentNotification: scene)
                .presentationDetents([.fraction(0.25)])  // 使用 fraction 設定 Sheet 高度為畫面的 25%
                .presentationDragIndicator(.visible)  // 顯示拖動條
        }
    }
    
    // 載入頁面時僅更新一次狀態欄文字
    func loadInitialStatusText() {
        currentStatusText = statusMessages.randomElement() ?? "喵咪睡著了"
    }
}


#Preview {
    CharacterPage()
}
