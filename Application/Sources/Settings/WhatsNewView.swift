//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalyticsSwiftUI
import SwiftUI

// MARK: View

struct WhatsNewView: View {
    let url: URL
    
    @StateObject private var model = WhatsNewViewModel()
    
    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ActivityIndicator()
            case let .loaded(localFileUrl: localFileUrl):
                WebView(request: URLRequest(url: localFileUrl))
            case let .failure(error: error):
                EmptyContentView(state: .failed(error: error))
            }
        }
        .navigationTitle(NSLocalizedString("What's new", comment: "Title displayed at the top of the What's new view"))
        .onAppear {
            model.url = url
        }
        .onChange(of: url) { newValue in
            model.url = newValue
        }
        .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
    }
}

// MARK: Analytics

private extension WhatsNewView {
    private var analyticsPageTitle: String {
        return AnalyticsPageTitle.whatsNew.rawValue
    }
    
    private var analyticsPageLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.application.rawValue]
    }
}

// MARK: Preview

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WhatsNewView(url: URL(string: "https://pastebin.com/raw/nmGqYFny")!)
        }
        .navigationViewStyle(.stack)
    }
}
