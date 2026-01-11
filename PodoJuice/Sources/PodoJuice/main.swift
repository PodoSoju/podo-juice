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

// 2. Find Soju installation
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

// 5. Monitor wineserver
let monitor = WineserverMonitor(winePrefix: config.winePrefix)
monitor.waitForExit()

print("[PodoJuice] App finished, exiting")
exit(0)
