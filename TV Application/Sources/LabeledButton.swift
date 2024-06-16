//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct LabeledButton: View {
    let icon: ImageResource
    let label: String
    let accessibilityLabel: String
    let accessibilityHint: String?
    let action: () -> Void

    @State private var isFocused = false

    init(icon: ImageResource, label: String, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.accessibilityLabel = accessibilityLabel ?? label
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    var body: some View {
        VStack {
            Button(action: action) {
                Image(icon)
                    .frame(width: 68)
                    .foregroundColor(isFocused ? .darkGray : .white)
                    .onParentFocusChange { isFocused = $0 }
                    .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
            }
            Text(label)
                .srgFont(.subtitle2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(isFocused ? .white : .gray)
        }
        .frame(width: 148)
    }
}

struct LabeledButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LabeledButton(icon: .episodes, label: "Episodes", action: {})
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
                .previewDisplayName("Short label")

            LabeledButton(icon: .favorite, label: "Watch later", action: {})
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
                .previewDisplayName("Long label")
        }
    }
}
