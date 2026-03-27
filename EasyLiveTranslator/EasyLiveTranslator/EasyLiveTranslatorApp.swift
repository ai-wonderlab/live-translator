import SwiftUI

@main
struct EasyLiveTranslatorApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea(.all)
                HomeView()
            }
        }
    }
}
