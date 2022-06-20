//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Introspect
import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct SettingsNavigationView: View {
    @FirstResponder private var firstResponder
    
    var body: some View {
        NavigationView {
            SettingsView()
                .toolbar {
                    ToolbarItem {
                        Button {
                            firstResponder.sendAction(#selector(SettingsNavigationHostViewController.close(_:)))
                        } label: {
                            Text(NSLocalizedString("Done", comment: "Done button title"))
                        }
                    }
                }
        }
        .navigationViewStyle(.stack)
        .introspectNavigationController { navigationController in
            let navigationBar = navigationController.navigationBar
            navigationBar.largeTitleTextAttributes = [
                .font: SRGFont.font(family: .display, weight: .bold, size: 34) as UIFont
            ]
            navigationBar.titleTextAttributes = [
                .font: SRGFont.font(family: .display, weight: .semibold, size: 17) as UIFont
            ]
        }
        .responderChain(from: firstResponder)
    }
}

// MARK: UIKit presentation

final class SettingsNavigationViewController: NSObject {
    @objc static func viewController() -> UIViewController {
        return SettingsNavigationHostViewController()
    }
}

private final class SettingsNavigationHostViewController: UIHostingController<SettingsNavigationView> {
    init() {
        super.init(rootView: SettingsNavigationView())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func close(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Preview

struct SettingsNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsNavigationView()
    }
}
