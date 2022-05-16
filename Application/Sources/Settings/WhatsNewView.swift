//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

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
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WhatsNewView(url: URL(string: "https://pastebin.com/raw/nmGqYFny")!)
        }
        .navigationViewStyle(.stack)
    }
}
