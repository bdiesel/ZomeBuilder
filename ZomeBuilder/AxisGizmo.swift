import SwiftUI

/// Tripod-style axis gizmo that tracks the orbit camera. Each line points
/// from the gizmo center toward the projected screen direction of the
/// matching world axis (red = X, green = Y, blue = Z). Y-up world.
///
/// Projection (right-handed Y-up, spherical camera at yaw/pitch around target):
///   world X (1,0,0) → screen ( cos(yaw),       sin(yaw)·sin(pitch))
///   world Y (0,1,0) → screen ( 0,             -cos(pitch))
///   world Z (0,0,1) → screen (-sin(yaw),       cos(yaw)·sin(pitch))
/// (SwiftUI canvas y is positive-down, hence the Y-axis sign flip.)
struct AxisGizmo: View {
    let yaw: Float
    let pitch: Float

    // SketchUp parity: red = horizontal (X), blue = up (Y), green = forward (Z).
    // The math is still RealityKit's Y-up — only the visible colours are remapped.
    private static let xColor = Color(red: 0.85, green: 0.20, blue: 0.20)
    private static let yColor = Color(red: 0.20, green: 0.40, blue: 0.95)
    private static let zColor = Color(red: 0.20, green: 0.70, blue: 0.25)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.15), radius: 4, y: 1)

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 14

                let cyaw = CGFloat(cos(yaw))
                let syaw = CGFloat(sin(yaw))
                let cp   = CGFloat(cos(pitch))
                let sp   = CGFloat(sin(pitch))

                struct Axis {
                    let name: String
                    let color: Color
                    let direction: CGPoint    // unit-length on screen plane
                    let depth: CGFloat        // -1..+1; > 0 = pointing into screen
                }

                let axes: [Axis] = [
                    .init(name: "X", color: Self.xColor,
                          direction: CGPoint(x:  cyaw, y:  syaw * sp),
                          depth:    -CGFloat(sin(yaw)) * cp),
                    .init(name: "Y", color: Self.yColor,
                          direction: CGPoint(x: 0,    y: -cp),
                          depth:    -CGFloat(sin(pitch))),
                    .init(name: "Z", color: Self.zColor,
                          direction: CGPoint(x: -syaw, y: cyaw * sp),
                          depth:    -CGFloat(cos(yaw)) * cp),
                ]

                // Draw far-pointing axes first; near-pointing on top.
                let sorted = axes.sorted { $0.depth > $1.depth }

                for axis in sorted {
                    let end = CGPoint(
                        x: center.x + radius * axis.direction.x,
                        y: center.y + radius * axis.direction.y
                    )

                    var stroke = Path()
                    stroke.move(to: center)
                    stroke.addLine(to: end)
                    context.stroke(
                        stroke,
                        with: .color(axis.color),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )

                    let dotSize: CGFloat = 5
                    let dotRect = CGRect(
                        x: end.x - dotSize / 2, y: end.y - dotSize / 2,
                        width: dotSize, height: dotSize
                    )
                    context.fill(Path(ellipseIn: dotRect), with: .color(axis.color))

                    // Label slightly past the endpoint, in the same direction.
                    let labelOffset: CGFloat = 9
                    let labelPoint = CGPoint(
                        x: end.x + axis.direction.x * labelOffset,
                        y: end.y + axis.direction.y * labelOffset
                    )
                    context.draw(
                        Text(axis.name)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(axis.color),
                        at: labelPoint,
                        anchor: .center
                    )
                }
            }
            .padding(8)
        }
        .frame(width: 84, height: 84)
    }
}

#Preview {
    HStack(spacing: 16) {
        AxisGizmo(yaw: 0.55, pitch: 0.32)
        AxisGizmo(yaw: 0,    pitch: 0)
        AxisGizmo(yaw: 1.57, pitch: 0.5)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
