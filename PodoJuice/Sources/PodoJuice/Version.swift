import Foundation

struct PodoJuiceVersion {
    static let major = 1
    static let minor = 0
    static let patch = 0
    static let build = 1
    
    static var string: String {
        "\(major).\(minor).\(patch)"
    }
    
    static var full: String {
        "\(major).\(minor).\(patch) (build \(build))"
    }
}
