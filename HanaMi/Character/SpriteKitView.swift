import SwiftUI
import SpriteKit

// SpriteKitView - 用 UIViewControllerRepresentable 嵌入 SKView 并设置透明背景
struct SpriteKitView: UIViewControllerRepresentable {
    
    var scene: SKScene
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let skView = SKView(frame: UIScreen.main.bounds)
        
        skView.allowsTransparency = true  // 确保支持透明背景
        skView.backgroundColor = .clear   // 将 SKView 背景设置为透明
        skView.presentScene(scene)        // 显示 SpriteKit 场景
        
        viewController.view = skView
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 不需要实时更新内容
    }
}
