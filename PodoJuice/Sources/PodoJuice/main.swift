import Foundation
import AppKit

// Initialize NSApplication for GUI support (alerts, etc.)
let app = NSApplication.shared
app.setActivationPolicy(.regular)

print("[PodoJuice] Starting...")
print("[PodoJuice] Bundle path: \(Bundle.main.bundlePath)")

// 1. Load configuration
guard let config = loadConfig() else {
    print("[PodoJuice] Failed to load configuration")
    PodoSojuLocator.showNotInstalledAlert()
    exit(1)
}

print("[PodoJuice] Configuration loaded:")
print("[PodoJuice]   Workspace: \(config.workspacePath)")
print("[PodoJuice]   Target: \(config.targetLnk)")
print("[PodoJuice]   Exe: \(config.exePath)")
print("[PodoJuice]   Unix path: \(config.unixExePath)")

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

// 4. Run Wine
let runner = WineRunner(sojuRoot: sojuRoot, config: config)
do {
    try runner.run()
} catch {
    print("[PodoJuice] Failed to start Wine: \(error)")

    let alert = NSAlert()
    alert.messageText = "Wine 실행 실패"
    alert.informativeText = error.localizedDescription
    alert.alertStyle = .critical
    alert.runModal()
    exit(1)
}

// 5. Monitor wineserver using Timer (non-blocking)
print("[PodoJuice] Monitoring wineserver...")

let monitor = WineserverMonitor(winePrefix: config.winePrefix)

// Wait a bit for wineserver to start
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    // Start monitoring timer
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        if !monitor.isRunning() {
            print("[PodoJuice] Wineserver exited, terminating...")
            timer.invalidate()
            NSApp.terminate(nil)
        }
    }
}

// Run the app event loop
app.run()
