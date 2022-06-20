//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct SearchSettingsNavigationView: View {
    let query: String?
    let settings: SRGMediaSearchSettings
    
    @FirstResponder private var firstResponder
    
    var body: some View {
        NavigationView {
            SearchSettingsView(query: query, settings: settings)
                .toolbar {
                    ToolbarItem {
                        Button {
                            firstResponder.sendAction(#selector(SearchSettingsNavigationViewController.close(_:)))
                        } label: {
                            Text(NSLocalizedString("OK", comment: "Title of the search settings button to apply settings"))
                        }
                    }
                }
        }
        .navigationViewStyle(.stack)
        .responderChain(from: firstResponder)
    }
}

// MARK: UIKit presentation

final class SearchSettingsNavigationViewController: UIHostingController<SearchSettingsNavigationView> {
    init(query: String?, settings: SRGMediaSearchSettings) {
        super.init(rootView: SearchSettingsNavigationView(query: query, settings: settings))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func close(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Preview

struct SearchSettingsNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        SearchSettingsNavigationView(query: nil, settings: SRGMediaSearchSettings())
    }
}


