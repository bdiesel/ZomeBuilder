# ZomeBuilder

A macOS app for designing parametric zome domes, with a companion visionOS app, ZomeVision, for exploring them in an immersive space. Built on [ZomeKit](https://github.com/bdiesel/swift-zomekit).

## Features
- **3D design (macOS):** adjust dome parameters in a sidebar and see the dome rendered with RealityKit.
- **Fabrication cut list:** grouped timber sizes and miter angles, exportable as CSV.
- **Metric or imperial units.**
- **Save and open designs** as documents.
- **ZomeVision (visionOS):** open a design in an immersive space and explore the dome around you.

## Structure
- `ZomeBuilder/`: macOS app (SwiftUI, RealityKit, AppKit)
- `ZomeVision/`: visionOS app (SwiftUI, RealityKit immersive space)
- Geometry comes from ZomeKit; both apps share a rendering layer.
