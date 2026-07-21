import SwiftUI

@main
struct DishdApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                switch appState.authStatus {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(DishdColor.screen)
                case .signedOut:
                    WelcomeView()
                case .signedIn:
                    if appState.needsOnboarding {
                        OnboardingFlow()
                    } else {
                        MainTabView()
                    }
                }
            }
            .environmentObject(appState)
            .preferredColorScheme(.light)   // v1 is light-only; dark theme is a v2 project
            .task { await appState.restoreSession() }
        }
    }
}
