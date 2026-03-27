import SwiftUI
import UIKit

@main
struct EasyLiveTranslatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup { HomeView() }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { return }

        let win = UIWindow(windowScene: ws)
        win.backgroundColor = .black

        // Force fill entire screen bounds
        let screen = ws.screen
        win.frame = screen.bounds
        win.bounds = CGRect(origin: .zero, size: screen.bounds.size)

        let host = UIHostingController(rootView: HomeView())
        host.view.backgroundColor = .black
        host.view.frame = screen.bounds
        host.additionalSafeAreaInsets = .zero

        win.rootViewController = host
        win.makeKeyAndVisible()
        self.window = win
    }
}
