import SwiftUI

struct ContentView: View {

    init() {
            // 強制將應用設置為淺色模式
            UIView.appearance().overrideUserInterfaceStyle = .light
        }

    var body: some View {
        StarterPage()
    }
}
