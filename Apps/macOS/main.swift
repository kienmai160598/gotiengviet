import Cocoa
import InputMethodKit
import os

private let logger = Logger(subsystem: "dev.vietkey.inputmethod", category: "server")

guard let connectionName = Bundle.main.object(forInfoDictionaryKey: "InputMethodConnectionName") as? String,
      let server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)
else {
    logger.fault("Cannot start IMKServer: missing InputMethodConnectionName or registration failed")
    exit(EXIT_FAILURE)
}

let tables = ContinuousClock().measure { _ = SharedModels.frequencies }
logger.info("Frequency tables loaded in \(tables, privacy: .public)")
logger.info("IMKServer started on \(connectionName, privacy: .public)")
withExtendedLifetime(server) {
    NSApplication.shared.run()
}
