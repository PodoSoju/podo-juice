import Foundation

/// Monitors Wine processes for a specific WINEPREFIX
struct WineserverMonitor {
    let winePrefix: String
    let sojuRoot: String

    init(winePrefix: String, sojuRoot: String = "") {
        self.winePrefix = winePrefix
        self.sojuRoot = sojuRoot
    }

    /// Check if wineserver is running for this prefix using wineserver -w 0
    public func isRunning() -> Bool {
        // Method 1: Check wineserver socket exists
        if hasWineserverSocket() {
            return true
        }

        // Method 2: Use wineserver -w 0 (wait with 0 timeout = just check)
        if !sojuRoot.isEmpty {
            return checkWineserverRunning()
        }

        return false
    }

    /// Check if wineserver socket exists for this prefix
    private func hasWineserverSocket() -> Bool {
        let fm = FileManager.default
        let prefixURL = URL(fileURLWithPath: winePrefix)

        // Find .wine-server-* directory
        guard let contents = try? fm.contentsOfDirectory(at: prefixURL, includingPropertiesForKeys: nil) else {
            return false
        }

        for url in contents {
            if url.lastPathComponent.hasPrefix(".wine-server-") {
                let socketPath = url.appendingPathComponent("socket")
                if fm.fileExists(atPath: socketPath.path) {
                    return true
                }
            }
        }
        return false
    }

    /// Use wineserver binary to check if running
    private func checkWineserverRunning() -> Bool {
        let wineserverPath = "\(sojuRoot)/bin/wineserver"
        guard FileManager.default.fileExists(atPath: wineserverPath) else {
            return false
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: wineserverPath)
        task.arguments = ["-w", "0"]  // Wait with 0 timeout = just check status
        task.environment = ["WINEPREFIX": winePrefix]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
            // wineserver -w returns 0 if server is running
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Wait for wineserver to start (with timeout)
    func waitForStart(timeout: TimeInterval = 30) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if isRunning() {
                print("[PodoJuice] Wineserver started")
                return true
            }
            Thread.sleep(forTimeInterval: 0.5)
        }

        print("[PodoJuice] Timeout waiting for wineserver to start")
        return false
    }

    /// Monitor wineserver and return when it exits
    func waitForExit(checkInterval: TimeInterval = 1.0) {
        print("[PodoJuice] Monitoring wineserver...")

        // Give wineserver time to start
        Thread.sleep(forTimeInterval: 2.0)

        while isRunning() {
            Thread.sleep(forTimeInterval: checkInterval)
        }

        print("[PodoJuice] Wineserver exited")
    }
}
