import SwiftUI

@main
struct MacSignerApp: App {
    @StateObject private var signerManager = SignerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(signerManager)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 500)

        Settings {
            SettingsView()
                .environmentObject(signerManager)
        }
    }
}
