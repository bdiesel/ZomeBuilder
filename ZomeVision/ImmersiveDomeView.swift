import SwiftUI
import RealityKit
import ZomeKit
import ZomeRendering

/// The dome rendered at 1:1 real-world scale inside an `ImmersiveSpace`.
/// ZomeKit values are inches by default; visionOS scenes are in metres,
/// so the root entity gets `inchesToMeters` scale and is positioned a
/// little ahead of the user — just outside the timbers — so they can
/// physically step in. Reads `params` from the shared `ZomeStore`, so
/// in-situ slider tweaks rebuild the dome live around the user.
struct ImmersiveDomeView: View {
    @Environment(ZomeStore.self) private var store
    let appearance: TimberAppearance

    private static let inchesToMeters: Float = 1.0 / 39.3701

    var body: some View {
        RealityView { content in
            let dome = Entity()
            dome.name = "dome"
            dome.transform.scale = SIMD3<Float>(repeating: Self.inchesToMeters)
            // Push the dome 1.5 m forward so the user starts outside the
            // wedge and can step in. Floor stays at Y = 0.
            dome.position = SIMD3<Float>(0, 0, -1.5)
            populate(dome, with: store.params)
            content.add(dome)
        } update: { content in
            // Live regen when params or appearance change. Camera-equivalent
            // motion (the user walking) is purely a head-tracking concern,
            // so update is only triggered by SwiftUI state changes.
            if let dome = content.entities.first(where: { $0.name == "dome" }) {
                populate(dome, with: store.params)
            }
        }
    }

    @MainActor
    private func populate(_ root: Entity, with params: ZomeParameters) {
        root.children.removeAll()
        let geom = Zome.build(params)
        for angle in geom.rotationAngles {
            let spiral = Entity()
            for timbers in geom.faceTimbers {
                for timber in timbers {
                    guard let mesh = try? timber.meshResource(scale: 1.0) else { continue }
                    let material = TimberMaterials.material(for: timber, appearance: appearance)
                    spiral.addChild(ModelEntity(mesh: mesh, materials: [material]))
                }
            }
            spiral.transform.rotation = simd_quatf(
                angle: -Float(angle),
                axis: SIMD3<Float>(0, 1, 0)
            )
            root.addChild(spiral)
        }
    }
}
