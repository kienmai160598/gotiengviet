import SwiftUI

@main
struct VietKeyApp: App {
    var body: some Scene {
        WindowGroup { SetupView() }
    }
}

/// How to turn the keyboard on, and a field to try it in.
struct SetupView: View {
    @Environment(\.openURL) private var openURL
    @State private var sample = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Turn on VietKey") {
                    Label("Open Settings, tap Keyboards, and turn on VietKey.", systemImage: "1.circle")
                    Button("Open Settings", action: openSettings)
                    Label("In any text field, touch and hold the globe key, then choose VietKey.", systemImage: "2.circle")
                }
                Section {
                    TextField("vieetj nam, then a space", text: $sample, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Try it")
                } footer: {
                    Text("Telex: type vieetj for việt. English words stay English: type text for text.")
                }
            }
            .navigationTitle("VietKey")
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}
