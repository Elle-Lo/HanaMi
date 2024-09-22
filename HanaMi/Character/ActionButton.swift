import SwiftUI

// 自定义按钮组件
struct ActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
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
}
