import Lottie
import SwiftUI

struct LottieView: UIViewRepresentable {
    
    var animationFileName: String
    @Binding var isPlaying: Bool
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: animationFileName)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.play { (finished) in
            if finished {
                isPlaying = false
            }
        }
        
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if isPlaying {
            uiView.play()
        }
    }
}

