import Foundation
import AppKit

/// Manages Wine process execution with process group tracking
class WineRunner {
    let sojuRoot: String
    let config: JuiceConfig

    /// The Wine process (kept for termination)
    private(set) var wineProcess: Process?

    /// Shared instance for termination handling
    static var shared: WineRunner?

    init(sojuRoot: String, config: JuiceConfig) {
        self.sojuRoot = sojuRoot
        self.config = config
    }

    /// Wine.app bundle path (LSUIElement=YES for Dock hiding)
    var wineAppPath: String {
        return "\(sojuRoot)/Wine.app"
    }

    /// Wine executable path (fallback if Wine.app doesn't exist)
    var winePath: String {
        let wine = "\(sojuRoot)/bin/wine"
        let wine64 = "\(sojuRoot)/bin/wine64"

        if FileManager.default.fileExists(atPath: wine) {
            return wine
        }
        return wine64
    }

    /// Check if Wine.app exists
    var hasWineApp: Bool {
        return FileManager.default.fileExists(atPath: wineAppPath)
    }

    /// Build environment variables for Wine
    func buildEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment

        // Wine configuration
        env["WINEPREFIX"] = config.winePrefix
        env["WINEDLLOVERRIDES"] = "winemenubuilder.exe=d"

        // Soju app info (for Dock title and icon)
        env["SOJU_APP_NAME"] = config.appName
        env["SOJU_APP_PATH"] = config.unixExePath
        env["SOJU_WORKSPACE_ID"] = config.workspaceId
        // SOJU_HIDE_DOCK modes:
        // 0 = Regular (default)
        // 1 = Accessory immediate
        // 2 = Regular->Accessory delayed
        // 3 = Keep current (for Wine.app with LSUIElement=YES)
        if hasWineApp {
            env["SOJU_HIDE_DOCK"] = "3"  // Wine.app + LSUIElement
        } else {
            env["SOJU_HIDE_DOCK"] = "2"  // Fallback
        }

        // Library paths for bundled dylibs
        let libPath = "\(sojuRoot)/lib"
        if let existingPath = env["DYLD_FALLBACK_LIBRARY_PATH"] {
            env["DYLD_FALLBACK_LIBRARY_PATH"] = "\(libPath):\(existingPath)"
        } else {
            env["DYLD_FALLBACK_LIBRARY_PATH"] = libPath
        }

        // PATH for wine binaries
        let binPath = "\(sojuRoot)/bin"
        if let existingPath = env["PATH"] {
            env["PATH"] = "\(binPath):\(existingPath)"
        } else {
            env["PATH"] = binPath
        }

        return env
    }

    /// Run Wine with the configured exe
    func run() throws {
        if hasWineApp {
            // Use Wine.app with NSWorkspace (LSUIElement=YES for proper Dock hiding)
            runWithWineApp()
        } else {
            // Fallback: direct wine binary execution
            try runWithWineBinary()
        }
    }

    /// Run using Wine.app bundle (recommended - LSUIElement hides from Dock)
    private func runWithWineApp() {
        let wineAppURL = URL(fileURLWithPath: wineAppPath)
        let env = buildEnvironment()

        print("[PodoJuice] Starting Wine.app (LSUIElement):")
        print("[PodoJuice]   App: \(wineAppPath)")
        print("[PodoJuice]   Exe: \(config.unixExePath)")
        print("[PodoJuice]   WINEPREFIX: \(config.winePrefix)")
        print("[PodoJuice]   App: \(config.appName)")

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = ["start", "/unix", config.unixExePath]
        configuration.environment = env
        configuration.activates = false  // Don't activate Wine app

        NSWorkspace.shared.openApplication(at: wineAppURL, configuration: configuration) { app, error in
            if let error = error {
                print("[PodoJuice] Failed to start Wine.app: \(error)")
            } else if let app = app {
                print("[PodoJuice] Wine.app started (PID: \(app.processIdentifier))")
            }
        }

        WineRunner.shared = self
    }

    /// Fallback: Run wine binary directly
    private func runWithWineBinary() throws {
        let process = Process()
        let env = buildEnvironment()

        process.executableURL = URL(fileURLWithPath: winePath)
        process.arguments = ["start", "/unix", config.unixExePath]
        process.environment = env
        process.currentDirectoryURL = URL(fileURLWithPath: config.workspacePath)

        print("[PodoJuice] Starting Wine (fallback):")
        print("[PodoJuice]   Executable: \(winePath)")
        print("[PodoJuice]   Arguments: \(process.arguments ?? [])")
        print("[PodoJuice]   WINEPREFIX: \(config.winePrefix)")
        print("[PodoJuice]   App: \(config.appName)")

        try process.run()

        wineProcess = process
        WineRunner.shared = self

        print("[PodoJuice] Wine process started (PID: \(process.processIdentifier))")
    }

    /// Terminate all Wine processes for this prefix
    func terminate() {
        print("[PodoJuice] Terminating Wine processes for prefix: \(config.winePrefix)")

        // 1. Kill by WINEPREFIX pattern
        let pkillTask = Process()
        pkillTask.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        pkillTask.arguments = ["-9", "-f", config.winePrefix]
        try? pkillTask.run()
        pkillTask.waitUntilExit()

        // 2. Use wineserver -k
        let wineserverPath = "\(sojuRoot)/bin/wineserver"
        let wineserverTask = Process()
        wineserverTask.executableURL = URL(fileURLWithPath: wineserverPath)
        wineserverTask.arguments = ["-k"]
        wineserverTask.environment = ["WINEPREFIX": config.winePrefix]
        try? wineserverTask.run()
        wineserverTask.waitUntilExit()

        // 3. Terminate direct child if still running
        if let process = wineProcess, process.isRunning {
            process.terminate()
        }

        print("[PodoJuice] Wine processes terminated")
    }
}
