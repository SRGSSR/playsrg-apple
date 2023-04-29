//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct HelpNavigationView: View {
    @FirstResponder private var firstResponder
    
    var body: some View {
        PlayNavigationView {
            HelpView()
                .toolbar {
                    ToolbarItem {
                        Button {
                            firstResponder.sendAction(#selector(HelpNavigationHostViewController.close(_:)))
                        } label: {
                            Text(NSLocalizedString("Done", comment: "Done button title"))
                        }
                    }
                }
        }
        .navigationViewStyle(.stack)
        .responderChain(from: firstResponder)
    }
}

// MARK: UIKit presentation

final class HelpNavigationViewController: NSObject {
    @objc static func viewController() -> UIViewController {
        return HelpNavigationHostViewController()
    }
}

private final class HelpNavigationHostViewController: UIHostingController<HelpNavigationView> {
    init() {
        super.init(rootView: HelpNavigationView())
    }
    
    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func close(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Preview

struct HelpNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        HelpNavigationView()
    }
}
