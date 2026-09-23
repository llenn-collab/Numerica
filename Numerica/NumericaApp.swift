import SwiftUI

@main
struct NumericaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .textEditing) {
                Button("Clear Input") {
                    NotificationCenter.default.post(name: .clearNumericaInput, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let clearNumericaInput = Notification.Name("Numerica.ClearInput")
}
