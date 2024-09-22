import SwiftUI

// 自定義按鈕組件
struct ActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .bold()
                .foregroundColor(.brown)
                .frame(width: 80, height: 40)  // 固定按鈕的寬度，避免被裁剪
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.8))  // 半透明背景
                        .shadow(radius: 3)  // 加陰影效果
                )
        }
    }
}
