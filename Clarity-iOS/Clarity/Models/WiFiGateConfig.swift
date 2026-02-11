import Foundation
import SwiftData

@Model
class WiFiGateConfig {
    var id: UUID = UUID()
    var isEnabled: Bool = true
    var homeNetworks: [String] = [] // SSIDs, max 3
    var strictMode: Bool = false // false = show override after 30s, true = no override

    init() {}
}
