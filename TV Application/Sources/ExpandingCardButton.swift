//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  A wrapper view for adding a card appearance to any view, expanding into all available space
 *  (unlike a usual card button which hugs its content).
 *
 *  Behavior: h-exp, v-exp
 */
struct ExpandingCardButton<Content: View>: View {
    private let action: () -> Void
    @Binding private var content: () -> Content
    
    fileprivate var onFocusChangeAction: ((Bool) -> Void)?
    
    @State private var isFocused = false
    
    init(action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        _content = .constant(content)
    }
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: action) {
                content()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onParentFocusChange { focused in
                        if let onFocusAction = onFocusChangeAction {
                            onFocusAction(focused)
                        }
                        isFocused = focused
                    }
            }
            .buttonStyle(FlatCardButtonStyle(focused: isFocused))
        }
    }
}

extension ExpandingCardButton {
    /**
     *  Attach an action triggered when a card button receives or loses focus.
     */
    func onFocusChange(perform action: @escaping (Bool) -> Void) -> ExpandingCardButton {
        var button = self
        button.onFocusChangeAction = action
        return button
    }
}

struct ExpandingCardButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExpandingCardButton(action: {}) {
                Color.red
            }
            
            ExpandingCardButton(action: {}) {
                Text("Button")
                    .background(Color.blue)
            }
        }
        .padding()
        .previewLayout(.fixed(width: 300, height: 300))
    }
}
