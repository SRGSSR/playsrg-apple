//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI
import WebKit

// MARK: View

struct WebView: UIViewControllerRepresentable {
    let request: URLRequest
    let customization: ((WKWebView) -> Void)?
    let decisionHandler: ((URL) -> WKNavigationActionPolicy)?

    init(request: URLRequest, customization: ((WKWebView) -> Void)? = nil, decisionHandler: ((URL) -> WKNavigationActionPolicy)? = nil) {
        self.request = request
        self.customization = customization
        self.decisionHandler = decisionHandler
    }

    func makeUIViewController(context _: Context) -> WebViewController {
        WebViewController(request: request, customizationBlock: customization, decisionHandler: decisionHandler)
    }

    func updateUIViewController(_: WebViewController, context _: Context) {
        // Never updated
    }
}

// MARK: Preview

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(request: URLRequest(url: URL(string: "https://www.srf.ch/play")!))
    }
}
