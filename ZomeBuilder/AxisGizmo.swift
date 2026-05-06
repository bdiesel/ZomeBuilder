import SwiftUI

/// SketchUp-style legend in the corner — colored bars with X/Y/Z labels so the
/// viewer can recognise the axes after orbiting. Static (not camera-tracked) for v1.
struct AxisGizmo: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.15), radius: 4, y: 1)

            VStack(alignment: .leading, spacing: 6) {
                axisRow(label: "X", color: Color(red: 0.85, green: 0.20, blue: 0.20))
                axisRow(label: "Y", color: Color(red: 0.20, green: 0.70, blue: 0.25))
                axisRow(label: "Z", color: Color(red: 0.20, green: 0.40, blue: 0.95))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: 86, height: 84)
    }

    private func axisRow(label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(color)
                .frame(width: 22, height: 3)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.black.opacity(0.85))
        }
    }
}

#Preview {
    AxisGizmo()
        .padding()
        .background(Color.gray.opacity(0.2))
}
