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
        let footings = Zome.footings(for: geom, params: params)

        // Position the dome so the floor (bottom of footings) sits on the
        // user's real floor, with the apex straight up. Push 1.5 m forward
        // so the user starts outside and can step in.
        // Lift = timberThickness in scene meters, since the dome's internal
        // Y origin is at the timber-floor level (not the footing-floor).
        let lift = Float(params.timberThickness) * Self.inchesToMeters
        root.position = SIMD3<Float>(0, lift, -1.5)

        for angle in geom.rotationAngles {
            let spiral = Entity()
            for timbers in geom.faceTimbers {
                for timber in timbers {
                    guard let mesh = try? timber.meshResource(scale: 1.0) else { continue }
                    let material = TimberMaterials.material(for: timber, appearance: appearance)
                    spiral.addChild(ModelEntity(mesh: mesh, materials: [material]))
                }
            }
            for footing in footings {
                guard let mesh = try? footing.meshResource(scale: 1.0) else { continue }
                let material = TimberMaterials.material(for: footing, appearance: appearance)
                spiral.addChild(ModelEntity(mesh: mesh, materials: [material]))
            }
            spiral.transform.rotation = simd_quatf(
                angle: -Float(angle),
                axis: SIMD3<Float>(0, 1, 0)
            )
            root.addChild(spiral)
        }
    }
}
