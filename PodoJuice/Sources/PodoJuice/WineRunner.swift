import Foundation

/// Manages Wine process execution
struct WineRunner {
    let sojuRoot: String
    let config: JuiceConfig

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

        print("[PodoJuice] Wine process started (PID: \(process.processIdentifier))")
    }
}
