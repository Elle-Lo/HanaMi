import SwiftUI

struct ContentView: View {

    init() {
            // 強制將應用設置為淺色模式
            UIView.appearance().overrideUserInterfaceStyle = .light
        for familyName in UIFont.familyNames {
            print(familyName)
            
            for fontName in
                UIFont.fontNames(forFamilyName: familyName) {
                print("--\(fontName)")
            }
        }
    }

    var body: some View {
        StarterPage()
    }
}
