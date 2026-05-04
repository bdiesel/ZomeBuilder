import SwiftUI
import ZomeKit

struct ContentView: View {
    @State private var params: ZomeParameters = .goodKarmaDefault

    var body: some View {
        HStack(spacing: 0) {
            ParameterSidebar(params: $params)
                .frame(width: 300)
            Divider()
            ZomeView(params: params)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
