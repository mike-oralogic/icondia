import SwiftUI

@main
struct ImageRegistrationApp: App {
    @State private var store = DraftStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ApplicationFormView(store: store)
            }
        }
    }
}
