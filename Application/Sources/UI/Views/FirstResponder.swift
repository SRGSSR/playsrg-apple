//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  A view providing access to the `UIKit` responder chain. Use the `FirstResponder` parameter provided to its view
 *  builder to send an event to the responder chain.
 */
struct ResponderChain<Content: View>: UIViewControllerRepresentable {
    private let content: (FirstResponder) -> Content
    
    init(@ViewBuilder content: @escaping (FirstResponder) -> Content) {
        self.content = content
    }
    
    class FirstResponder {
        fileprivate weak var view: UIView?
        
        @discardableResult
        func sendAction(_ action: Selector, for event: UIEvent? = nil) -> Bool {
            return UIApplication.shared.sendAction(action, to: nil, from: view, for: event)
        }
    }
    
    func makeCoordinator() -> FirstResponder {
        return FirstResponder()
    }
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let coordinator = context.coordinator
        let hostController = UIHostingController(rootView: content(coordinator), ignoreSafeArea: true)
        
        if let hostView = hostController.view {
            coordinator.view = hostView
            hostView.backgroundColor = .clear
            hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        return hostController
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
        uiViewController.rootView = content(context.coordinator)
    }
}
