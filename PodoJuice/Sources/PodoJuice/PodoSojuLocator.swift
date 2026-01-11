import Foundation
import AppKit

/// Locates PodoSoju installation on the system
struct PodoSojuLocator {
    /// Known locations where PodoSoju might be installed
    static let searchPaths = [
        "~/Library/Application Support/com.soju.app/Libraries/Soju",
        "~/Library/Application Support/com.podosoju.app/Libraries/Soju",
        "/Applications/PodoSoju.app/Contents/Resources/soju",
        "~/Applications/PodoSoju.app/Contents/Resources/soju",
        "/usr/local/soju",
        "~/.local/share/soju"
    ]

    /// Find PodoSoju installation, returns the soju root path
    static func find() -> String? {
        for path in searchPaths {
            let expanded = (path as NSString).expandingTildeInPath

            // Check for wine or wine64 binary
            let winePath = "\(expanded)/bin/wine"
            let wine64Path = "\(expanded)/bin/wine64"

            if FileManager.default.fileExists(atPath: winePath) ||
               FileManager.default.fileExists(atPath: wine64Path) {
                print("[PodoJuice] Found PodoSoju at: \(expanded)")
                return expanded
            }
        }

        print("[PodoJuice] PodoSoju not found in any known location")
        print("[PodoJuice] Searched paths: \(searchPaths)")
        return nil
    }

    /// Show alert when PodoSoju is not installed
    static func showNotInstalledAlert() {
        let alert = NSAlert()
        alert.messageText = "PodoSoju가 설치되어 있지 않습니다"
        alert.informativeText = "이 앱을 실행하려면 PodoSoju가 필요합니다.\nPodoSoju를 먼저 설치해주세요."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "PodoSoju 다운로드")
        alert.addButton(withTitle: "취소")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "https://podosoju.app") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
