import SwiftUI
import UIKit

@main
struct EasyLiveTranslatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Force all windows to use our bg color — no system chrome gaps
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.backgroundColor = UIColor(red: 0.030, green: 0.038, blue: 0.065, alpha: 1)
                    window.rootViewController?.view.backgroundColor = UIColor(red: 0.030, green: 0.038, blue: 0.065, alpha: 1)
                }
            }
        }
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let bgColor = UIColor(red: 0.030, green: 0.038, blue: 0.065, alpha: 1)
        let hosting = UIHostingController(rootView: HomeView())
        hosting.view.backgroundColor = bgColor
        hosting.view.insetsLayoutMarginsFromSafeArea = false

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = bgColor
        window.rootViewController = hosting
        window.makeKeyAndVisible()

        // Force frame to fill entire screen
        hosting.view.frame = window.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.window = window
    }
}
