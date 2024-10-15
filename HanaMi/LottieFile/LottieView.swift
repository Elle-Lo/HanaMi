import Lottie
import SwiftUI

struct LottieView: UIViewRepresentable {
    
    var animationFileName: String
    var loopMode: LottieLoopMode = .playOnce  // 預設為播放一次
    @Binding var isPlaying: Bool
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: animationFileName)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode  // 使用傳入的 loopMode
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if isPlaying {
            uiView.play { finished in
                if finished {
                    isPlaying = false  // 播放完成後設為 false
                }
            }
        } else {
            uiView.stop()
        }
    }
}
