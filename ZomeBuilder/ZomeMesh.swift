import Foundation
import RealityKit
import ZomeKit

/// Indices into a ZomeTimber's 8 corners for its 6 faces, matching builder.rb's PRISM_FACES.
/// Order: top, bottom, back, front, right, left.
private let prismFaces: [(Int, Int, Int, Int)] = [
    (1, 0, 2, 3),   // top      (sits on the outer dome surface)
    (5, 4, 6, 7),   // bottom   (inner)
    (1, 5, 7, 3),   // back
    (0, 4, 6, 2),   // front
    (3, 2, 6, 7),   // right
    (1, 0, 4, 5),   // left
]

extension ZomeTimber {
    /// Build a flat-shaded MeshResource for this 8-vertex prism. Vertices are
    /// duplicated per face so each face gets its own normal — gives clean,
    /// readable timber edges instead of smooth-blended ones.
    func meshResource(scale: Float = 1.0) throws -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        positions.reserveCapacity(prismFaces.count * 4)
        normals.reserveCapacity(prismFaces.count * 4)
        indices.reserveCapacity(prismFaces.count * 6)

        for (i0, i1, i2, i3) in prismFaces {
            let p0 = SIMD3<Float>(points[i0]) * scale
            let p1 = SIMD3<Float>(points[i1]) * scale
            let p2 = SIMD3<Float>(points[i2]) * scale
            let p3 = SIMD3<Float>(points[i3]) * scale

            // Plane intersections can produce slightly non-planar quads; the
            // normal of the (p0,p1,p2) triangle is a good-enough average.
            let n = simd_normalize(simd_cross(p1 - p0, p2 - p0))

            let base = UInt32(positions.count)
            positions.append(contentsOf: [p0, p1, p2, p3])
            normals.append(contentsOf: Array(repeating: n, count: 4))
            indices.append(contentsOf: [base, base + 1, base + 2, base, base + 2, base + 3])
        }

        var descriptor = MeshDescriptor(name: "timber")
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }
}
