import SwiftUI
import RealityKit
import ZomeKit

struct ContentView: View {
    /// Scene-space scale factor: ZomeKit values are unitless (Brian's defaults
    /// are inches). 1/100 puts the 122″ default zome at ~1.22 scene units —
    /// a comfortable distance for the orbit camera.
    private let scale: Float = 0.01

    private let geometry: ZomeGeometry = Zome.build(.goodKarmaDefault)

    var body: some View {
        RealityView { content in
            let dome = Entity()
            dome.addChild(buildWedge())

            for angle in geometry.rotationAngles.dropFirst() {
                let spiral = buildWedge()
                // z5omes generates the wedge at angle 0; rotate around -Y so
                // spiral indices wind the same way as the source app.
                spiral.transform.rotation = simd_quatf(
                    angle: -Float(angle),
                    axis: SIMD3<Float>(0, 1, 0)
                )
                dome.addChild(spiral)
            }

            // Center the dome vertically on the camera target.
            let halfHeight = Float(geometry.parameters.zomeHeight) * scale * 0.5
            dome.position = SIMD3<Float>(0, -halfHeight, 0)
            content.add(dome)

            // Soft directional light + a faint ambient, since SimpleMaterial
            // wants something to react to.
            let key = DirectionalLight()
            key.light.intensity = 4000
            key.orientation = simd_quatf(
                angle: -.pi / 3,
                axis: SIMD3<Float>(1, 0.4, 0)
            )
            content.add(key)
        }
        .realityViewCameraControls(.orbit)
        .background(Color(white: 0.10))
    }

    /// Build one spiral wedge as a child-entity tree. Each timber is its own
    /// ModelEntity for now — easy to wire up per-timber selection later.
    private func buildWedge() -> Entity {
        let wedge = Entity()
        for timbers in geometry.faceTimbers {
            for timber in timbers {
                guard let mesh = try? timber.meshResource(scale: scale) else { continue }
                let color = RainbowPalette.color(for: timber)
                let material = SimpleMaterial(color: color, roughness: 0.6, isMetallic: false)
                let entity = ModelEntity(mesh: mesh, materials: [material])
                wedge.addChild(entity)
            }
        }
        return wedge
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
