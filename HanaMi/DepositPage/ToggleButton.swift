import SwiftUI

struct ToggleButton: View {
    @Binding var isPublic: Bool

    var body: some View {
        Button(action: {
            isPublic.toggle()
        }) {
            Text(isPublic ? "公 開" : "私 人")
                .font(.system(size: 15))
                .fontWeight(.bold)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .foregroundColor(isPublic ? Color(hex: "#522504") : Color.colorYellow)
                .background(isPublic ? Color.colorYellow : Color(hex: "#522504"))
                .cornerRadius(10)
        }
        .padding(.trailing, 10)
    }
}
