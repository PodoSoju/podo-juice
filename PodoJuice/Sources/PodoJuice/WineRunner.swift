import Foundation

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

    /// Wine executable path (prefers wine, falls back to wine64)
    var winePath: String {
        let wine = "\(sojuRoot)/bin/wine"
        let wine64 = "\(sojuRoot)/bin/wine64"

        if FileManager.default.fileExists(atPath: wine) {
            return wine
        }
        return wine64
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

        // SOJU_HIDE_DOCK: Hide Wine from Dock
        // Mode 2: TransformProcessType before NSApp creation (wine-fork patch)
        env["SOJU_HIDE_DOCK"] = "2"

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

    /// Write hide dock setting to WINEPREFIX for all Wine processes to read
    private func writeHideDockSetting() {
        let sojuDir = URL(fileURLWithPath: config.winePrefix).appendingPathComponent(".soju")
        let hideDockFile = sojuDir.appendingPathComponent("hide_dock")

        // Create .soju directory if needed
        try? FileManager.default.createDirectory(at: sojuDir, withIntermediateDirectories: true)

        // Write hide_dock mode (2 = TransformProcessType before NSApp)
        try? "2".write(to: hideDockFile, atomically: true, encoding: .utf8)
        print("[PodoJuice] Wrote hide_dock setting to \(hideDockFile.path)")
    }

    /// Run Wine with the configured exe
    func run() throws {
        // Write hide dock setting for all Wine processes
        writeHideDockSetting()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: winePath)
        process.arguments = ["start", "/unix", config.unixExePath]
        process.environment = buildEnvironment()
        process.currentDirectoryURL = URL(fileURLWithPath: config.workspacePath)

        print("[PodoJuice] Starting Wine:")
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
