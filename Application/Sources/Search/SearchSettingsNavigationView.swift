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
        PlayNavigationView {
            SearchSettingsView(query: $model.query, settings: $model.settings)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        // TODO: Starting with iOS 16 we can put the if on the toolbar item directly
                        if !model.hasDefaultSettings {
                            Button {
                                model.resetSettings()
                            } label: {
                                Text(NSLocalizedString("Reset", comment: "Title of the reset search settings button"))
                            }
                        }
                    }

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

    @available(*, unavailable)
    @MainActor dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredContentSize: CGSize {
        get {
            CGSize(width: 375, height: 800)
        }
        set {}
    }

    @objc fileprivate func close(_: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Preview

struct SearchSettingsNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        SearchSettingsNavigationView(model: SearchViewModel())
    }
}
