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
    let label: String?
    let accessibilityLabel: String
    let accessibilityHint: String?
    let action: () -> Void
    
    @State private var isFocused = false
    
    init(icon: String, label: String? = nil, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        let accessibilityLabel = accessibilityLabel ?? label
        assert(accessibilityLabel != nil, "Simple button must have an accessibility label.")
        
        self.icon = icon
        self.label = label
        self.accessibilityLabel = accessibilityLabel ?? icon // Use icon name as dirty fallback.
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(icon)
                if let label = label {
                    Text(label)
                        .srgFont(.button)
                        .lineLimit(1)
                }
            }
            .onParentFocusChange { isFocused = $0 }
            .padding(.horizontal, constant(iOS: 10, tvOS: 16))
            .padding(.vertical, constant(iOS: 8, tvOS: 12))
            .foregroundColor(constant(iOS: .srgGrayC7, tvOS: isFocused ? .srgGray23 : .srgGrayC7))
            .background(constant(iOS: Color.srgGray23, tvOS: Color.clear))
            .cornerRadius(constant(iOS: LayoutStandardViewCornerRadius, tvOS: 0))
            .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
        }
    }
}

struct SimpleButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SimpleButton(icon: "favorite", label: "Add to favorites", action: {})
                .padding()
                .previewLayout(.sizeThatFits)
            SimpleButton(icon: "favorite", action: {})
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
