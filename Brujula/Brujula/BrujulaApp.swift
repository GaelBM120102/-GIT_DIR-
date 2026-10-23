import SwiftUI

@main
struct BrujulaApp: App {
    @StateObject private var store = LifeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environment(\.locale, Locale(identifier: "es_MX"))
                .preferredColorScheme(store.data.appearance == "dark" ? .dark : store.data.appearance == "light" ? .light : nil)
                .tint(Palette.green)
        }
    }
}
