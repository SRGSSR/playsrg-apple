//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  A wrapper view for adding a card appearance to any view.
 *
 *  Behavior: h-cha, v-cha
 *
 *  @discussion Also fixes an issue with tvOS card buttons applying the `View/fixedSize(width:height:)` modifier
 *              to the content.
 */
struct CardButton<Content: View>: View {
    private let action: (() -> Void)?
    fileprivate var onFocusChangeAction: ((Bool) -> Void)?
    private let content: () -> Content
    
    init(action: (() -> Void)?, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                if let action = action {
                    action()
                }
            }) {
                content()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onParentFocusChange { focused in
                        if let onFocusAction = self.onFocusChangeAction {
                            onFocusAction(focused)
                        }
                    }
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}

extension CardButton {
    /**
     *  Attach an action triggered when a card button receives or loses focus.
     */
    func onFocusChange(perform action: @escaping (Bool) -> Void) -> CardButton {
        var button = self
        button.onFocusChangeAction = action
        return button
    }
}

/**
 *  A wrapper view created for adding a card appearance to any view, with a
 *  label underneath which automatically scales when the card is focused.
 *
 *  @discussion Behaves like a button from content sizing. Use a parent geometry reader if needed.
 */
struct LabeledCardButton<Content: View, Label: View>: View {
    private let action: (() -> Void)?
    fileprivate var onFocusChangeAction: ((Bool) -> Void)?
    
    private let content: () -> Content
    private let label: () -> Label
    
    @State private var isFocused = false
    
    init(action: (() -> Void)?, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.content = content
        self.label = label
    }
    
    var body: some View {
        VStack {
            CardButton(action: action) {
                content()
            }
            .onFocusChange { focused in
                isFocused = focused
                
                if let onFocusAction = self.onFocusChangeAction {
                    onFocusAction(focused)
                }
            }
                
            label()
                .opacity(isFocused ? 1 : 0.5)
                .offset(x: 0, y: isFocused ? 10 : 0)
                .scaleEffect(isFocused ? 1.1 : 1, anchor: .top)
                .animation(.easeInOut(duration: 0.2))
        }
    }
}

extension LabeledCardButton {
    func onFocusChange(perform action: @escaping (Bool) -> Void) -> LabeledCardButton {
        var button = self
        button.onFocusChangeAction = action
        return button
    }
}
