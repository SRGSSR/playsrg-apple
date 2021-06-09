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
 *  Behavior: h-neu, v-neu
 */
struct ResponderChain<Content: View>: UIViewRepresentable {
    private let content: (FirstResponder) -> Content
    
    init(@ViewBuilder content: @escaping (FirstResponder) -> Content) {
        self.content = content
    }
    
    func makeCoordinator() -> Coordinator {
        let firstResponder = FirstResponder()
        let hostController = UIHostingController(rootView: content(firstResponder), ignoreSafeArea: true)
        return Coordinator(firstResponder: firstResponder, hostController: hostController)
    }
    
    func makeUIView(context: Context) -> UIView {
        let hostView = context.coordinator.hostController.view!
        hostView.backgroundColor = .clear
        context.coordinator.firstResponder.view = hostView
        return hostView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator
        
        let hostController = coordinator.hostController
        hostController.rootView = content(coordinator.firstResponder)
        
        // Make layout neutral
        uiView.applySizingBehavior(of: hostController)
    }
}

// MARK: Types

extension ResponderChain {
    struct Coordinator {
        let firstResponder: FirstResponder
        let hostController: UIHostingController<Content>
    }
    
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
