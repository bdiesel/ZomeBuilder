import Foundation
import ZomeKit

/// Display unit selection. ZomeKit math + ZomeParameters values are
/// always stored as inches internally (matches the package defaults);
/// this enum just picks how lengths are shown to the user.
enum UnitSystem: Int, CaseIterable, Identifiable, Sendable {
    case imperial = 0
    case metric = 1

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .imperial: return "Imperial"
        case .metric:   return "Metric"
        }
    }

    var suffix: String {
        switch self {
        case .imperial: return "in"
        case .metric:   return "mm"
        }
    }

    /// Slider step, expressed in the **internal** unit (inches), that
    /// corresponds to 1 unit of display granularity (1/16″ vs 1 mm).
    var lengthStepInches: Double {
        switch self {
        case .imperial: return 1.0 / 16.0
        case .metric:   return 1.0 / 25.4
        }
    }

    /// Format an inch length into a human-readable string in this unit system.
    func formatLength(inches v: Double) -> String {
        switch self {
        case .imperial:
            return CutList.formatInches(v)
        case .metric:
            let mm = v * 25.4
            return "\(Int(mm.rounded())) mm"
        }
    }

    /// AppStorage key used across the app for the user's choice.
    static let storageKey = "unitSystem"
}
