import SwiftUI
import RealityKit
import ZomeKit

/// 3D viewport that rebuilds the zome whenever `params` changes.
struct ZomeView: View {
    let params: ZomeParameters

    /// Scene-space scale: ZomeKit values are unitless (Brian's defaults are
    /// inches). 1/100 places the 122″ default zome at ~1.22 scene units.
    private let scale: Float = 0.01

    var body: some View {
        RealityView { content in
            // One-time setup: directional key light + a named root for the dome
            // that the update closure replaces children of.
            let key = DirectionalLight()
            key.light.intensity = 4000
            key.orientation = simd_quatf(
                angle: -.pi / 3,
                axis: SIMD3<Float>(1, 0.4, 0)
            )
            content.add(key)

            let dome = Entity()
            dome.name = "dome"
            content.add(dome)

            populate(dome, with: params)
        } update: { content in
            guard let dome = content.entities.first(where: { $0.name == "dome" }) else { return }
            populate(dome, with: params)
        }
        .realityViewCameraControls(.orbit)
        .background(Color(white: 0.10))
    }

    private func populate(_ root: Entity, with params: ZomeParameters) {
        root.children.removeAll()
        let geom = Zome.build(params)

        for angle in geom.rotationAngles {
            let spiral = makeSpiral(geom)
            spiral.transform.rotation = simd_quatf(
                angle: -Float(angle),
                axis: SIMD3<Float>(0, 1, 0)
            )
            root.addChild(spiral)
        }

        let halfHeight = Float(geom.parameters.zomeHeight) * scale * 0.5
        root.position = SIMD3<Float>(0, -halfHeight, 0)
    }

    private func makeSpiral(_ geom: ZomeGeometry) -> Entity {
        let wedge = Entity()
        for timbers in geom.faceTimbers {
            for timber in timbers {
                guard let mesh = try? timber.meshResource(scale: scale) else { continue }
                let color = RainbowPalette.color(for: timber)
                let material = SimpleMaterial(color: color, roughness: 0.6, isMetallic: false)
                wedge.addChild(ModelEntity(mesh: mesh, materials: [material]))
            }
        }
        return wedge
    }
}
