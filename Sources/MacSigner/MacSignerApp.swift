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
        .defaultSize(width: 600, height: 550)

        Settings {
            TabView {
                ServerConfigView()
                    .environmentObject(signerManager)
                    .tabItem {
                        Label("服务器", systemImage: "network")
                    }
                AppleCredentialView()
                    .environmentObject(signerManager)
                    .tabItem {
                        Label("Apple 帐号", systemImage: "person.crop.circle")
                    }
            }
            .padding(.top, 40)
            .frame(width: 580, height: 440)
        }
    }
}
