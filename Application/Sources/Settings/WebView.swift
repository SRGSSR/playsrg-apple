//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct WebView: UIViewControllerRepresentable {
    let request: URLRequest
    
    // TODO: Add block parameters for view controller init as well as modifiers for analytics info
    
    func makeUIViewController(context: Context) -> WebViewController {
        return WebViewController(request: request, customizationBlock: nil, decisionHandler: nil)
    }
    
    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        // Never updated
    }
}

// MARK: Preview

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(request: URLRequest(url: URL(string: "https://www.srf.ch/play")!))
    }
}
