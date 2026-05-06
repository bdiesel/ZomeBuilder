import SwiftUI
import ZomeKit

struct ContentView: View {
    @State private var params: ZomeParameters = .goodKarmaDefault
    @State private var showBoundingBox: Bool = false

    private var geometry: ZomeGeometry { Zome.build(params) }

    var body: some View {
        HStack(spacing: 0) {
            ParameterSidebar(
                params: $params,
                showBoundingBox: $showBoundingBox,
                geometry: geometry
            )
            .frame(width: 300)

            Divider()

            ZomeView(params: params, showBoundingBox: showBoundingBox)
                .overlay(alignment: .bottomLeading) {
                    AxisGizmo()
                        .padding(12)
                }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
