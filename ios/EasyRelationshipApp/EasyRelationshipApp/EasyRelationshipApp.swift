import SwiftUI
import EasyRelationshipCore

@main
struct EasyRelationshipApp: App {
    private let environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            AppRootView(environment: environment)
        }
    }
}

