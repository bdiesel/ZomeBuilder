import SwiftUI
import ZomeKit
import ZomeRendering

/// 2D launcher window. Shows the active design's envelope and a button to
/// enter / exit the immersive scene.
struct LauncherView: View {
    @Binding var params: ZomeParameters

    @Environment(\.openImmersiveSpace)    private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var immersiveOpen: Bool = false

    private var geometry: ZomeGeometry { Zome.build(params) }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("ZomeVision")
                    .font(.largeTitle.weight(.bold))
                Text("Walk inside your zome at 1:1 scale")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                row("Height",   value: CutList.formatInches(geometry.envelope.height))
                row("Diameter", value: CutList.formatInches(geometry.envelope.diameter))
                row("Crowns",   value: "\(geometry.crownCount)")
                row("Timbers",  value: "\(geometry.envelope.timbersPerSpiral * params.numSpirals)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.regularMaterial)
            )

            Button(action: toggleImmersive) {
                Text(immersiveOpen ? "Exit Zome" : "Enter Zome")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
        .frame(minWidth: 380, minHeight: 360)
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }

    private func toggleImmersive() {
        Task {
            if immersiveOpen {
                await dismissImmersiveSpace()
                immersiveOpen = false
            } else {
                switch await openImmersiveSpace(id: "immersive") {
                case .opened:
                    immersiveOpen = true
                case .userCancelled, .error:
                    immersiveOpen = false
                @unknown default:
                    immersiveOpen = false
                }
            }
        }
    }
}
