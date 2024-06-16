//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  A wrapper view adding a card button to some content view at the top (with some aspect ratio or, if omitted, its
 *  own intrinsic aspect ratio), and displaying a label underneath which scales when the button has the focus.
 *
 *  Content is assigned to the button area and is provided all the space it needs. In the remaining space below
 *  a label can be displayed.
 *
 *  Behavior: h-exp, v-exp
 */
struct LabeledCardButton<Content: View, Label: View>: View {
    private let aspectRatio: CGFloat?
    private let action: () -> Void
    @Binding private var content: () -> Content
    @Binding private var label: () -> Label

    fileprivate var onFocusChangeAction: ((Bool) -> Void)?

    @State private var isFocused = false

    init(aspectRatio: CGFloat? = nil, action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: @escaping () -> Label) {
        self.aspectRatio = aspectRatio
        self.action = action
        _content = .constant(content)
        _label = .constant(label)
    }

    var body: some View {
        VStack(spacing: 0) {
            ExpandingCardButton(action: action) {
                content()
            }
            .onFocusChange { focused in
                isFocused = focused

                if let onFocusAction = onFocusChangeAction {
                    onFocusAction(focused)
                }
            }
            .aspectRatio(aspectRatio, contentMode: .fit)
            .layoutPriority(1)

            label()
                .opacity(isFocused ? 1 : 0.8)
                .offset(x: 0, y: isFocused ? 10 : 0)
                .scaleEffect(isFocused ? 1.1 : 1, anchor: .top)
                .animation(.easeInOut(duration: 0.1))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct LabeledCardButton_Previews: PreviewProvider {
    private static let aspectRatio: CGFloat? = 16 / 9

    static var previews: some View {
        Group {
            LabeledCardButton(aspectRatio: aspectRatio, action: {}) {
                Color.red
            } label: {
                Color.blue
            }

            LabeledCardButton(aspectRatio: aspectRatio, action: {}) {
                Color.red
            } label: {
                Text("Label")
            }

            LabeledCardButton(aspectRatio: aspectRatio, action: {}) {
                Text("Button")
            } label: {
                Color.blue
            }

            LabeledCardButton(aspectRatio: aspectRatio, action: {}) {
                Text("Button")
            } label: {
                Text("Label")
            }
        }
        .padding()
        .previewLayout(.fixed(width: 300, height: 300))
    }
}
