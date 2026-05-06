import SwiftUI
import RealityKit
import ZomeKit

/// 3D viewport for the zome. Custom orbit camera (drag = rotate, scroll wheel = zoom).
struct ZomeView: View {
    let params: ZomeParameters
    let showBoundingBox: Bool

    /// Scene-space scale: ZomeKit values are unitless (Brian's defaults are
    /// inches). 1/100 places the 122″ default zome at ~1.22 scene units.
    private let scale: Float = 0.01

    // Orbit camera state. Right-handed, Y-up; spherical coordinates around `target`.
    @State private var yaw: Float = 0.55
    @State private var pitch: Float = 0.32
    @State private var distance: Float = 3.5
    @State private var dragStart: (yaw: Float, pitch: Float)? = nil

    /// Reference type held in `@State` so dome-rebuild gating survives across
    /// body re-evaluations without triggering further re-evaluations on mutation.
    @State private var cache = BuildCache()

    private let target: SIMD3<Float> = SIMD3<Float>(0, 0.5, 0)

    var body: some View {
        let inner = sceneView
        #if canImport(AppKit)
        ScrollWheelHost(onScroll: handleScroll) { inner }
        #else
        inner
        #endif
    }

    @ViewBuilder
    private var sceneView: some View {
        RealityView { content in
            // One-time setup — lights, axes, camera, dome container, envelope box.
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

            let envelope = EnvelopeBox.makeEmpty()
            content.add(envelope)

            let geom = Zome.build(params)
            populate(dome, with: geom)
            EnvelopeBox.populate(envelope, envelope: geom.envelope, scale: scale)
            envelope.isEnabled = showBoundingBox
            cache.lastBuiltParams = params

            camera.look(at: target, from: cameraPosition(), relativeTo: nil)
        } update: { content in
            // Rebuild dome + envelope box only when params actually change.
            if cache.lastBuiltParams != params {
                let geom = Zome.build(params)
                if let dome = content.entities.first(where: { $0.name == "dome" }) {
                    populate(dome, with: geom)
                }
                if let box = content.entities.first(where: { $0.name == "envelopeBox" }) {
                    EnvelopeBox.populate(box, envelope: geom.envelope, scale: scale)
                }
                cache.lastBuiltParams = params
            }
            // Toggle visibility (cheap; no rebuild).
            if let box = content.entities.first(where: { $0.name == "envelopeBox" }) {
                box.isEnabled = showBoundingBox
            }
            // Camera updates are a single matrix.
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

    private func populate(_ root: Entity, with geom: ZomeGeometry) {
        root.children.removeAll()
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
                let material = doubleSidedMaterial(color: RainbowPalette.color(for: timber))
                wedge.addChild(ModelEntity(mesh: mesh, materials: [material]))
            }
        }
        return wedge
    }

    /// Double-sided so the dome reads cleanly from inside (visionOS walk-through)
    /// AND from outside the wedge during orbit. PhysicallyBasedMaterial is the
    /// only built-in that exposes face culling.
    private func doubleSidedMaterial(color: PlatformColor) -> PhysicallyBasedMaterial {
        var pbr = PhysicallyBasedMaterial()
        pbr.baseColor = .init(tint: color)
        pbr.roughness = .init(floatLiteral: 0.6)
        pbr.metallic = .init(floatLiteral: 0.0)
        pbr.faceCulling = .none
        return pbr
    }
}

/// Mutable holder for build-result caching. Class so mutations don't
/// trigger SwiftUI body re-evaluations the way a struct `@State` would.
private final class BuildCache {
    var lastBuiltParams: ZomeParameters?
}
