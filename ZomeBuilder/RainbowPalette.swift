import Foundation
import ZomeKit

#if canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#endif

/// Per-timber rainbow coloring. Same timbers (same length within 1/16″ at the
/// chosen unit scale) get the same color, so cut-list groupings read at a glance.
/// Matches the z5omes 3D-viewport look.
enum RainbowPalette {
    static func color(for timber: ZomeTimber) -> PlatformColor {
        let m = CutList.measure(timber)
        // Bucket by length only (in sixteenths of whatever unit ZomeKit was
        // given). Miter angles carry less visual signal for the rainbow.
        let bucket = Int((m.length * 16).rounded())
        let hue = CGFloat(stableHash(bucket) % 360) / 360.0
        return PlatformColor(hue: hue, saturation: 0.65, brightness: 0.78, alpha: 1.0)
    }

    /// Stable across runs. `Int.hashValue` is randomised per process; this is not.
    private static func stableHash(_ value: Int) -> Int {
        // Knuth's multiplicative hash, masked to non-negative.
        let h = UInt64(bitPattern: Int64(value)) &* 2_654_435_761
        return Int(truncatingIfNeeded: h & 0x7FFF_FFFF)
    }
}
