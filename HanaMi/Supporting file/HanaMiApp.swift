import SwiftUI
import Firebase
import FirebaseCore
import IQKeyboardManagerSwift

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct HanaMiApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    init() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 0 // 关闭默认的距离调整
        }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
