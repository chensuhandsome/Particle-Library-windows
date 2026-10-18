import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var menuChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    let menuChannel = FlutterMethodChannel(
      name: "pdg.menu",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    self.menuChannel = menuChannel

    super.awakeFromNib()

    // macOS can keep an old Dock icon cached for the same bundle path across
    // rebuilds. Set the icon explicitly from the current AppIcon.icns so the
    // running app and the pinned Dock tile agree with the bundle.
    // Load the same PNG that Flutter uses for its BrandMark. Reading the
    // image from the app bundle directly avoids the stale IconServices cache
    // that can keep an older owl in the Dock after a rebuild.
    let iconCandidates = [
      Bundle.main.bundleURL.appendingPathComponent(
        "Contents/Frameworks/App.framework/Resources/flutter_assets/assets/brand/app_icon.png"
      ),
      Bundle.main.bundleURL.appendingPathComponent(
        "Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/brand/app_icon.png"
      ),
      Bundle.main.bundleURL.appendingPathComponent(
        "Contents/Resources/app_icon.png"
      ),
    ]
    if let iconURL = iconCandidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }),
       let icon = NSImage(contentsOf: iconURL) {
      NSApp.applicationIconImage = icon
      NSApp.dockTile.display()
    }

    // A particle-data browser benefits from a wide, readable window while the
    // layout still collapses to a single column below 760 logical pixels.
    // Apply the frame after super.awakeFromNib so a restored frame cannot
    // override the initial size on first launch.
    self.minSize = NSSize(width: 360, height: 560)
    self.title = "Particle Library"
    self.setContentSize(NSSize(width: 1400, height: 900))
    self.center()

    let debugChannel = FlutterMethodChannel(
      name: "pdg.debug",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    debugChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self, call.method == "resize",
            let args = call.arguments as? [String: Any],
            let width = args["width"] as? Double,
            let height = args["height"] as? Double else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.setContentSize(NSSize(width: width, height: height))
      self.center()
      result(nil)
    }
  }
  @IBAction func showAppHelp(_ sender: Any?) {
    menuChannel?.invokeMethod("showHelp", arguments: nil)
  }

  @IBAction func showSettings(_ sender: Any?) {
    menuChannel?.invokeMethod("showSettings", arguments: nil)
  }
}
