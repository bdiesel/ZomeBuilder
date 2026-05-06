import SwiftUI
import ZomeKit

struct ContentView: View {
    @State private var params: ZomeParameters = .goodKarmaDefault

    private var geometry: ZomeGeometry { Zome.build(params) }

    var body: some View {
        HStack(spacing: 0) {
            ParameterSidebar(params: $params, geometry: geometry)
                .frame(width: 300)
            Divider()
            ZomeView(params: params)
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
