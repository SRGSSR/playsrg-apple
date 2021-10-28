//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct ExpandingButton: View {
    let icon: String?
    let label: String
    let accessibilityLabel: String
    let accessibilityHint: String?
    let action: () -> Void
    
    @State private var isFocused = false
        
    init(icon: String? = nil, label: String, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.accessibilityLabel = accessibilityLabel ?? label
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(icon)
                }
                Text(label)
                    .srgFont(.button)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onParentFocusChange { isFocused = $0 }
        .foregroundColor(constant(iOS: .srgGrayC7, tvOS: isFocused ? .srgGray23 : .srgGrayC7))
        .background(constant(iOS: Color.srgGray23, tvOS: Color.clear))
        .cornerRadius(constant(iOS: LayoutStandardViewCornerRadius, tvOS: 0))
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
    }
}

// MARK: Preview

struct ExpandingButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExpandingButton(icon: "a_to_z", label: "A to Z", action: {})
                .padding()
                .previewLayout(.fixed(width: 240, height: 120))
            ExpandingButton(icon: "a_to_z", label: "A to Z", action: {})
                .padding()
                .previewLayout(.fixed(width: 120, height: 60))
            ExpandingButton(label: "A to Z", action: {})
                .padding()
                .previewLayout(.fixed(width: 120, height: 60))
        }
    }
}
