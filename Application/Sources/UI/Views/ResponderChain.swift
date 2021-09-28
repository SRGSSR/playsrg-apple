//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: Modifier

extension View {
    /**
     *  Provide access to the `UIKit` responder chain, rooted in a first responder inserted where the modifier
     *  is applied.
     *
     *  Behavior: h-neu, v-neu
     */
    func responderChain(from firstResponder: Binding<FirstResponder>) -> some View {
        return background(ResponderChain(firstResponder: firstResponder))
    }
}

// MARK: View

/**
 *  A view providing access to the `UIKit` responder chain by binding to a `UIKit` first responder view.
 */
private struct ResponderChain: UIViewRepresentable {
    @Binding var firstResponder: FirstResponder
    
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        firstResponder.view = uiView
    }
}

// MARK: Types

/**
 *  Provide access to the responder chain by inserting a first responder where the `responderChain(from:)` modifier
 *  is applied.
 */
@propertyWrapper class FirstResponder {
    // `FirstResponder` is a class so that we can modify the view during UI updates without SwiftUI detecting a change
    // (which would lead to undefined behavior). Declaring it as a property wrapper is only syntactic sugar to provide
    // for a more expressive formalism with no need to call the default constructor.
    fileprivate weak var view: UIView?
    
    var wrappedValue: FirstResponder {
        return self
    }
    
    var projectedValue: Binding<FirstResponder> {
        return .constant(self)
    }
    
    @discardableResult
    func sendAction(_ action: Selector, for event: UIEvent? = nil) -> Bool {
        return UIApplication.shared.sendAction(action, to: nil, from: view, for: event)
    }
}
