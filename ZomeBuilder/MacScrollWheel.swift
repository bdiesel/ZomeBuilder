#if canImport(AppKit)
import SwiftUI
import AppKit

/// Wraps SwiftUI content in an NSView that intercepts `scrollWheel` events.
/// Mouse / drag / keyboard events flow through the embedded NSHostingView
/// normally — only the scroll wheel is consumed here so we can drive a
/// custom camera dolly. `delta` is positive when the user physically
/// scrolls up (zoom-in convention), with macOS "natural scrolling" inverted
/// back to the device direction.
struct ScrollWheelHost<Content: View>: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void
    let content: Content

    init(onScroll: @escaping (CGFloat) -> Void, @ViewBuilder content: () -> Content) {
        self.onScroll = onScroll
        self.content = content()
    }

    func makeNSView(context: Context) -> NSView {
        let container = ScrollContainerView()
        container.onScroll = onScroll

        let host = NSHostingView(rootView: content)
        host.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(host)
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: container.topAnchor),
            host.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            host.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        context.coordinator.host = host
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let container = nsView as? ScrollContainerView {
            container.onScroll = onScroll
        }
        context.coordinator.host?.rootView = content
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var host: NSHostingView<Content>?
    }

    private final class ScrollContainerView: NSView {
        var onScroll: ((CGFloat) -> Void)?

        override func scrollWheel(with event: NSEvent) {
            // Use precise deltas for trackpad; magnify wheel deltas for mouse.
            let raw: CGFloat = event.hasPreciseScrollingDeltas
                ? event.scrollingDeltaY
                : event.scrollingDeltaY * 8
            // Convert "natural scrolling" back to device direction so the
            // physical-scroll-up gesture always means zoom-in.
            let physical = event.isDirectionInvertedFromDevice ? -raw : raw
            onScroll?(physical)
        }
    }
}
#endif
