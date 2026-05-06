import SwiftUI
import RealityKit
import ZomeKit
import ZomeRendering

/// The dome rendered at 1:1 real-world scale inside an `ImmersiveSpace`.
/// ZomeKit values are inches by default; visionOS scenes are in metres,
/// so the root entity gets `inchesToMeters` scale and is positioned a
/// little ahead of the user — just outside the timbers — so they can
/// physically step in.
struct ImmersiveDomeView: View {
    let params: ZomeParameters
    let appearance: TimberAppearance

    private static let inchesToMeters: Float = 1.0 / 39.3701

    var body: some View {
        RealityView { content in
            content.add(buildDome())
        }
    }

    @MainActor
    private func buildDome() -> Entity {
        let root = Entity()
        root.name = "dome"
        root.transform.scale = SIMD3<Float>(repeating: Self.inchesToMeters)

        // Place the dome's ground plane (Y = 0 in zome coords) on the user's
        // floor, with the apex straight up. Push it 1.5 m forward so the
        // user starts outside the wedge and can step in.
        root.position = SIMD3<Float>(0, 0, -1.5)

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
        return root
    }
}
