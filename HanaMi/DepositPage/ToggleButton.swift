import SwiftUI

struct ToggleButton: View {
    @Binding var isPublic: Bool

    var body: some View {
        Button(action: {
            isPublic.toggle()
        }) {
            Text(isPublic ? "公 開" : "私 人")
                .font(.system(size: 13)) // 增加字體大小
                .fontWeight(.bold) // 加粗字體
                .padding(.vertical, 13) // 增加內邊距，讓按鈕看起來更大
                .padding(.horizontal, 20)
                .foregroundColor(isPublic ? Color(hex: "#522504") : Color(hex: "#FFF7EF")) // 公開/私人字體顏色
                .background(isPublic ? Color(hex: "#FFF7EF") : Color(hex: "#522504")) // 公開/私人背景顏色
                .cornerRadius(25) // 加大圓角半徑，讓它更加圓弧狀
        }
    }
}
