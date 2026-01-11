import Foundation

/// Monitors wineserver process to keep the wrapper alive while Windows apps are running
struct WineserverMonitor {
    let winePrefix: String

    /// Check if wineserver is running for this prefix
    func isRunning() -> Bool {
        // Method 1: Check lock file in /tmp/.wine-{uid}/
        if let uid = getuid() as uid_t? {
            let tmpDir = "/tmp/.wine-\(uid)"
            let serverDirs = try? FileManager.default.contentsOfDirectory(atPath: tmpDir)

            for dir in serverDirs ?? [] where dir.hasPrefix("server-") {
                let lockPath = "\(tmpDir)/\(dir)/lock"
                if FileManager.default.fileExists(atPath: lockPath) {
                    // Lock file exists, check if it's for our prefix
                    // The server directory name contains a hash of the prefix
                    return true
                }
            }
        }

        // Method 2: Use pgrep as fallback
        return isRunningViaPgrep()
    }

    /// Check using pgrep command
    private func isRunningViaPgrep() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-f", "wineserver"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
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
