import SwiftUI
import UIKit

enum LinkType {
    case youtube
    case googleMaps
    case regular
}

struct LinkPreviewView: View {
    let url: URL
    let displayText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 显示链接文本
            Text(displayText)
                .font(.headline)
                .foregroundColor(.blue) // 蓝色显示链接
                .underline() // 给链接加下划线
                .onTapGesture {
                    UIApplication.shared.open(url) // 点击链接跳转
                }

            Text(url.absoluteString)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                .background(Color.white)
                .cornerRadius(12)
        )
    }
}
