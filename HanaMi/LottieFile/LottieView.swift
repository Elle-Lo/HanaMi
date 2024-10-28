import Lottie
import SwiftUI

struct LottieView: UIViewRepresentable {
    
    var animationFileName: String
    var loopMode: LottieLoopMode = .playOnce
    @Binding var isPlaying: Bool
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: animationFileName)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if isPlaying {
            uiView.play { finished in
                if finished {
                    isPlaying = false 
                }
            }
        } else {
            uiView.stop()
        }
    }
}
