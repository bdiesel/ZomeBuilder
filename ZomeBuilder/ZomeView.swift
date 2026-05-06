import SwiftUI
import RealityKit
import ZomeKit

/// 3D viewport for the zome. Custom orbit camera (drag = rotate, scroll wheel = zoom).
struct ZomeView: View {
    let params: ZomeParameters

    /// Scene-space scale: ZomeKit values are unitless (Brian's defaults are
    /// inches). 1/100 places the 122″ default zome at ~1.22 scene units.
    private let scale: Float = 0.01

    // Orbit camera state. Right-handed, Y-up; spherical coordinates around `target`.
    @State private var yaw: Float = 0.55
    @State private var pitch: Float = 0.32
    @State private var distance: Float = 3.5
    @State private var dragStart: (yaw: Float, pitch: Float)? = nil

    private let target: SIMD3<Float> = SIMD3<Float>(0, 0.5, 0)

    var body: some View {
        let scene = sceneView
        #if canImport(AppKit)
        ScrollWheelHost(onScroll: handleScroll) { scene }
        #else
        scene
        #endif
    }

    @ViewBuilder
    private var sceneView: some View {
        RealityView { content in
            // One-time setup — lights, axes, camera, and the dome container.
            let key = DirectionalLight()
            key.light.intensity = 4000
            key.orientation = simd_quatf(angle: -.pi / 3, axis: SIMD3<Float>(1, 0.4, 0))
            content.add(key)

            content.add(WorldAxes.makeReference())

            let camera = PerspectiveCamera()
            camera.name = "camera"
            camera.camera.fieldOfViewInDegrees = 45
            content.add(camera)

            let dome = Entity()
            dome.name = "dome"
            content.add(dome)

            populate(dome, with: params)
            if let cam = content.entities.first(where: { $0.name == "camera" }) {
                cam.look(at: target, from: cameraPosition(), relativeTo: nil)
            }
        } update: { content in
            if let dome = content.entities.first(where: { $0.name == "dome" }) {
                populate(dome, with: params)
            }
            if let cam = content.entities.first(where: { $0.name == "camera" }) {
                cam.look(at: target, from: cameraPosition(), relativeTo: nil)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.92), Color(white: 0.78)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .gesture(orbitDrag())
    }

    private func handleScroll(delta: CGFloat) {
        // Positive delta = scroll up = zoom in. Geometric step so the feel is
        // the same near and far.
        let factor = pow(0.985, Float(delta))
        distance = min(20, max(0.6, distance * factor))
    }

    private func orbitDrag() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStart == nil { dragStart = (yaw, pitch) }
                let start = dragStart ?? (yaw, pitch)
                let dx = Float(value.translation.width) * 0.008
                let dy = Float(value.translation.height) * 0.008
                yaw = start.yaw - dx
                pitch = max(-.pi / 2 + 0.05, min(.pi / 2 - 0.05, start.pitch + dy))
            }
            .onEnded { _ in dragStart = nil }
    }

    private func cameraPosition() -> SIMD3<Float> {
        let cosP = cos(pitch)
        return SIMD3<Float>(
            target.x + distance * cosP * sin(yaw),
            target.y + distance * sin(pitch),
            target.z + distance * cosP * cos(yaw)
        )
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
