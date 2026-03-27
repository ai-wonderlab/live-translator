import SwiftUI
import UIKit

@main
struct EasyLiveTranslatorApp: App {
    init() {
        // Force opaque full-screen background
        UIView.appearance(whenContainedInInstancesOf: [UIWindow.self]).backgroundColor = UIColor(red: 0.030, green: 0.038, blue: 0.065, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
