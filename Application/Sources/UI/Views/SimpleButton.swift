//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

/// Behavior: h-hug, v-hug
struct SimpleButton: View {
    let icon: String
    let label: String
    let accessibilityLabel: String
    let accessibilityHint: String?
    let action: () -> Void
    
    @State private var isFocused = false
    
    init(icon: String, label: String, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.accessibilityLabel = accessibilityLabel ?? label
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(icon)
                Text(label)
                    .srgFont(.button)
                    .lineLimit(1)
            }
            .onParentFocusChange { isFocused = $0 }
            .padding(.horizontal, constant(iOS: 10, tvOS: 16))
            .padding(.vertical, constant(iOS: 8, tvOS: 12))
            .foregroundColor(constant(iOS: .srgGray5, tvOS: isFocused ? .srgGray2 : .srgGray5))
            .background(constant(iOS: Color.srgGray2, tvOS: Color.clear))
            .cornerRadius(constant(iOS: LayoutStandardViewCornerRadius, tvOS: 0))
            .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
        }
    }
}

struct SimpleButton_Previews: PreviewProvider {
    static var previews: some View {
        SimpleButton(icon: "favorite", label: "Add to favorites", action: {})
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
