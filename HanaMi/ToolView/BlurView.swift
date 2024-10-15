import SwiftUI

// BlurView 用於背景模糊效果
struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
