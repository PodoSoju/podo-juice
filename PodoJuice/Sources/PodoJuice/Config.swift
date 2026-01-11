import Foundation

/// Configuration stored in Resources/config.json inside the .app bundle
struct JuiceConfig: Codable {
    let workspaceId: String
    let workspacePath: String
    let targetLnk: String
    let exePath: String  // Windows path: C:\Program Files\...

    /// Unix path derived from exePath and workspacePath
    var unixExePath: String {
        // Convert Windows path to Unix path
        // C:\Program Files\App\app.exe -> {workspacePath}/drive_c/Program Files/App/app.exe
        guard exePath.count >= 2, exePath.dropFirst().first == ":" else {
            return exePath
        }

        let drive = exePath.first!.lowercased()
        let remainder = String(exePath.dropFirst(2))
            .replacingOccurrences(of: "\\", with: "/")

        return "\(workspacePath)/drive_\(drive)\(remainder)"
    }

    /// App name derived from targetLnk
    var appName: String {
        URL(fileURLWithPath: targetLnk)
            .deletingPathExtension()
            .lastPathComponent
    }

    /// Wine prefix path
    var winePrefix: String {
        workspacePath
    }
}

/// Load config from the app bundle's Resources directory
func loadConfig() -> JuiceConfig? {
    guard let resourcesPath = Bundle.main.resourcePath else {
        print("[PodoJuice] Error: Could not find Resources path")
        return nil
    }

    let configPath = (resourcesPath as NSString).appendingPathComponent("config.json")
    let configURL = URL(fileURLWithPath: configPath)

    guard FileManager.default.fileExists(atPath: configPath) else {
        print("[PodoJuice] Error: config.json not found at \(configPath)")
        return nil
    }

    do {
        let data = try Data(contentsOf: configURL)
        let config = try JSONDecoder().decode(JuiceConfig.self, from: data)
        return config
    } catch {
        print("[PodoJuice] Error loading config: \(error)")
        return nil
    }
}
