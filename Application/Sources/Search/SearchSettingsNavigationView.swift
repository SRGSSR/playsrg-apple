//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct SearchSettingsNavigationView: View {
    @ObservedObject var model: SearchViewModel
    
    @FirstResponder private var firstResponder
    
    var body: some View {
        NavigationView {
            SearchSettingsView(model: model)
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
    init(model: SearchViewModel) {
        super.init(rootView: SearchSettingsNavigationView(model: model))
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
        SearchSettingsNavigationView(model: SearchViewModel())
    }
}


