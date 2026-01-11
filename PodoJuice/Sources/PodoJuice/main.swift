import Foundation
import AppKit

// MARK: - Version Check
if CommandLine.arguments.contains("--version") {
    print(PodoJuiceVersion.string)
    exit(0)
}

// MARK: - Loading Window
class LoadingWindowController {
    let window: NSWindow
    let spinner: NSProgressIndicator
    let label: NSTextField
    let appName: String

    init(appName: String) {
        self.appName = appName

        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 80),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = appName
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.level = .floating

        // Content view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 80))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Spinner
        spinner = NSProgressIndicator(frame: NSRect(x: 85, y: 40, width: 30, height: 30))
        spinner.style = .spinning
        spinner.controlSize = .regular
        spinner.startAnimation(nil)
        contentView.addSubview(spinner)

        // Label
        label = NSTextField(frame: NSRect(x: 10, y: 10, width: 180, height: 20))
        label.stringValue = "시작하는 중..."
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 12)
        contentView.addSubview(label)

        window.contentView = contentView
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window.close()
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    let winePrefix: String
    var sojuRoot: String = ""

    init(winePrefix: String) {
        self.winePrefix = winePrefix
        super.init()
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("[PodoJuice] Terminating...")
        // Use WineRunner's terminate method
        WineRunner.shared?.terminate()
    }
}

// MARK: - Main
let app = NSApplication.shared
app.setActivationPolicy(.regular)

print("[PodoJuice] Starting...")
print("[PodoJuice] Bundle: \(Bundle.main.bundlePath)")

// 1. Load configuration
guard let config = loadConfig() else {
    print("[PodoJuice] Failed to load configuration")
    PodoSojuLocator.showNotInstalledAlert()
    exit(1)
}

print("[PodoJuice] v\(PodoJuiceVersion.full)")
print("[PodoJuice] App: \(config.appName)")
print("[PodoJuice] Exe: \(config.exePath)")

// 2. Find PodoSoju installation
guard let sojuRoot = PodoSojuLocator.find() else {
    PodoSojuLocator.showNotInstalledAlert()
    exit(1)
}

// 3. Verify exe exists
guard FileManager.default.fileExists(atPath: config.unixExePath) else {
    print("[PodoJuice] Error: Exe not found at \(config.unixExePath)")
    let alert = NSAlert()
    alert.messageText = "실행 파일을 찾을 수 없습니다"
    alert.informativeText = "경로: \(config.unixExePath)"
    alert.alertStyle = .critical
    alert.runModal()
    exit(1)
}

// Set up app delegate
let appDelegate = AppDelegate(winePrefix: config.winePrefix)
appDelegate.sojuRoot = sojuRoot
app.delegate = appDelegate

// 4. Show loading window
let loadingWindow = LoadingWindowController(appName: config.appName)
loadingWindow.show()

// 5. Run Wine
let runner = WineRunner(sojuRoot: sojuRoot, config: config)
do {
    try runner.run()
} catch {
    print("[PodoJuice] Failed to start Wine: \(error)")
    loadingWindow.close()
    let alert = NSAlert()
    alert.messageText = "Wine 실행 실패"
    alert.informativeText = error.localizedDescription
    alert.alertStyle = .critical
    alert.runModal()
    exit(1)
}

// 6. Monitor .soju/running/ for Wine window (soju patch creates JSON here)
let monitor = WineserverMonitor(winePrefix: config.winePrefix)
let runningDir = URL(fileURLWithPath: config.winePrefix).appendingPathComponent(".soju/running")
var loadingClosed = false
var wineWindowWasOpened = false  // Track if Wine window was ever opened
var wineWindowStableCount = 0  // Require window to be stable for multiple checks
var wineWindowGoneCount = 0  // Track consecutive checks where window is gone

print("[PodoJuice] Watching for Wine window in: \(runningDir.path)")

// Track my exe name for pairing
let myExeName = URL(fileURLWithPath: config.unixExePath).lastPathComponent.lowercased()

DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
        // Check if MY running JSON file exists (match by exe path)
        var hasMyRunningFile = false

        if let files = try? FileManager.default.contentsOfDirectory(atPath: runningDir.path) {
            for file in files where file.hasSuffix(".json") {
                let filePath = runningDir.appendingPathComponent(file)
                if let data = try? Data(contentsOf: filePath),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let exePath = json["exe"] as? String {
                    // Check if this JSON is for MY exe
                    let jsonExeName = URL(fileURLWithPath: exePath).lastPathComponent.lowercased()
                    if jsonExeName == myExeName || exePath.lowercased().contains(myExeName) {
                        hasMyRunningFile = true
                        break
                    }
                }
            }
        }

        if hasMyRunningFile {
            wineWindowWasOpened = true
        }

        // Check if actual Wine window is fully visible on screen (always check, not just during loading)
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []

        var foundVisibleWindow = false
        for windowInfo in windowList {
            if let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
               ownerName.lowercased().contains("wine") {
                // Check if window has actual size and is fully opaque
                if let bounds = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                   let width = bounds["Width"], let height = bounds["Height"],
                   width > 100 && height > 100 {
                    // Check alpha (1.0 = fully visible)
                    let alpha = windowInfo[kCGWindowAlpha as String] as? CGFloat ?? 0
                    if alpha >= 1.0 {
                        foundVisibleWindow = true
                        break
                    }
                }
            }
        }

        // Loading window handling
        if !loadingClosed {
            if foundVisibleWindow {
                wineWindowStableCount += 1
                // Require 5 consecutive detections (0.3s * 5 = 1.5s of stable window)
                if wineWindowStableCount >= 5 {
                    print("[PodoJuice] Wine window stable for 1.5s, closing loading window")
                    loadingWindow.close()
                    loadingClosed = true

                    // Activate Wine app to bring window to foreground (with retry)
                    activateWineApp()
                }
            } else {
                wineWindowStableCount = 0  // Reset if window disappears
            }
        }

        // Exit conditions:
        // 1. Wine window was fully visible then disappeared (CGWindowList check)
        // 2. Running JSON file removed (soju patch signal)
        // 3. Wineserver exited (fallback)
        if loadingClosed && !foundVisibleWindow {
            // Loading closed means window was shown, now check if it's gone
            wineWindowGoneCount += 1
            if wineWindowGoneCount >= 3 {  // Gone for 0.9s
                print("[PodoJuice] Wine window closed, terminating...")
                timer.invalidate()
                NSApp.terminate(nil)
            }
        } else {
            wineWindowGoneCount = 0
        }

        if wineWindowWasOpened && !hasMyRunningFile {
            print("[PodoJuice] Wine running file removed, terminating...")
            timer.invalidate()
            NSApp.terminate(nil)
        } else if !monitor.isRunning() {
            print("[PodoJuice] Wineserver exited, terminating...")
            timer.invalidate()
            NSApp.terminate(nil)
        }
    }
}

// MARK: - Wine Activation Helper
func activateWineApp(retry: Int = 10) {
    guard let wineApp = NSWorkspace.shared.runningApplications.first(where: {
        $0.localizedName?.lowercased().contains("wine") == true
    }) else {
        if retry > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                activateWineApp(retry: retry - 1)
            }
        } else {
            print("[PodoJuice] Wine app not found after retries")
        }
        return
    }

    // Activate with all options
    let success = wineApp.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
    print("[PodoJuice] Activated Wine app: \(wineApp.localizedName ?? "unknown"), success: \(success)")

    // Retry if activation failed
    if !success && retry > 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            activateWineApp(retry: retry - 1)
        }
    }
}

// Fallback: close loading window after 15 seconds
DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
    if !loadingClosed {
        print("[PodoJuice] Timeout, closing loading window")
        loadingWindow.close()
        loadingClosed = true
    }
}

// Run the app event loop
app.run()
