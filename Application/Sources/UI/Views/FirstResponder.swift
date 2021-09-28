//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/**
 *  A view providing access to the `UIKit` responder chain. Use the `FirstResponder` parameter provided to its view
 *  builder to send an event to the responder chain.
 *
 *  Behavior: h-exp, v-exp
 */
struct ResponderChain<Content: View>: UIViewControllerRepresentable {
    @Binding private var content: (FirstResponder) -> Content
    
    init(@ViewBuilder content: @escaping (FirstResponder) -> Content) {
        _content = .constant(content)
    }
    
    func makeCoordinator() -> FirstResponder {
        return FirstResponder()
    }
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let coordinator = context.coordinator
        let hostController = UIHostingController(rootView: content(coordinator), ignoreSafeArea: true)
        if let hostView = hostController.view {
            hostView.backgroundColor = .clear
            coordinator.view = hostView
        }
        return hostController
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
        uiViewController.rootView = content(context.coordinator)
    }
}

// MARK: Types

extension ResponderChain {
    class FirstResponder {
        fileprivate weak var view: UIView?
        
        @discardableResult
        func sendAction(_ action: Selector, for event: UIEvent? = nil) -> Bool {
            return UIApplication.shared.sendAction(action, to: nil, from: view, for: event)
        }
    }
}

// MARK: Preview

struct ResponderChain_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ResponderChain { _ in
                Color.red
            }
            ResponderChain { _ in
                Text("Text")
            }
        }
        .border(Color.blue, width: 3)
        .previewLayout(.fixed(width: 400, height: 400))
    }
}
