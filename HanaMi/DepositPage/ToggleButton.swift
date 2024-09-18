import SwiftUI

struct ToggleButton: View {
    @Binding var isPublic: Bool

    var body: some View {
        Button(action: {
            isPublic.toggle()
        }) {
            Text(isPublic ? "公開" : "私人")
                .font(.system(size: 16))
                .fontWeight(.medium)
                .padding()
                .frame(width: 80)
                .foregroundColor(isPublic ? .white : .gray)
                .background(isPublic ? Color.orange : Color(UIColor.systemGray5))
                .cornerRadius(10)
        }
    }
}

