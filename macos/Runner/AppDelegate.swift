import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationWillFinishLaunching(_ notification: Notification) {
    // A second copy must not open another SQLite writer/window. Activate the
    // existing instance and exit before the Flutter engine starts.
    guard let bundleId = Bundle.main.bundleIdentifier else { return }
    let currentPid = ProcessInfo.processInfo.processIdentifier
    let existing = NSRunningApplication
      .runningApplications(withBundleIdentifier: bundleId)
      .first { $0.processIdentifier != currentPid && !$0.isTerminated }
    if let existing {
      existing.activate(options: [.activateAllWindows])
      NSApp.terminate(nil)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
