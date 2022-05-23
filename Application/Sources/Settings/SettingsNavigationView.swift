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
                            firstResponder.sendAction(#selector(SettingsNavigationViewController.close(_:)))
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

class SettingsNavigationViewController: UIViewController {
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .systemBackground
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hostController = UIHostingController(rootView: SettingsNavigationView())
        addChild(hostController)
        
        if let hostView = hostController.view {
            hostView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hostView)
            
            NSLayoutConstraint.activate([
                hostView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                hostView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                hostView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                hostView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        hostController.didMove(toParent: self)
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
