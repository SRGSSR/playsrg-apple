//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct SimpleButton: View {
    let icon: String
    let label: String?
    let accessibilityLabel: String
    let accessibilityHint: String?
    let action: () -> Void
    
    @State private var isFocused = false
    
    init(icon: String, accessibilityLabel: String, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = nil
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
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
                if let label = label {
                    Text(label)
                        .srgFont(.button)
                        .lineLimit(1)
                }
            }
            .onParentFocusChange { isFocused = $0 }
            .foregroundColor(.srgGrayC7)
            .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
        }
        .buttonStyle(FlatButtonStyle(focused: isFocused))
    }
}

// MARK: Preview

struct SimpleButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SimpleButton(icon: "favorite", label: "Add to favorites", action: {})
            SimpleButton(icon: "favorite", accessibilityLabel: "Add to favorites", action: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
