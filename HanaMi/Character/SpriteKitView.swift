import SwiftUI
import SpriteKit

struct SpriteKitView: UIViewControllerRepresentable {
    
    var scene: SKScene
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let skView = SKView(frame: UIScreen.main.bounds)
        
        skView.allowsTransparency = true
        skView.backgroundColor = .clear
        skView.presentScene(scene)
        
        viewController.view = skView
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
