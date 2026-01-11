import Foundation

/// Monitors Wine processes for a specific WINEPREFIX
struct WineserverMonitor {
    let winePrefix: String

    /// Check if any Wine process is running for this prefix
    public func isRunning() -> Bool {
        // pgrep -f finds processes with winePrefix in command line or environment
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-f", winePrefix]

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
