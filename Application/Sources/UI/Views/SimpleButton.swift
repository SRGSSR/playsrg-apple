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
    private let icon: ImageResource
    private let label: String?
    private let labelMinimumScaleFactor: CGFloat?
    private let accessibilityLabel: String
    private let accessibilityHint: String?
    private let action: () -> Void
    
    @State private var isFocused = false
    
    init(icon: ImageResource, accessibilityLabel: String, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = nil
        self.labelMinimumScaleFactor = nil
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    init(icon: ImageResource, label: String, labelMinimumScaleFactor: CGFloat = 0.8, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.labelMinimumScaleFactor = labelMinimumScaleFactor
        self.accessibilityLabel = accessibilityLabel ?? label
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(icon)
                if let label {
                    Text(label)
                        .srgFont(.button)
                        .minimumScaleFactor(labelMinimumScaleFactor ?? 1)
                        .lineLimit(1)
                }
            }
            .onParentFocusChange { isFocused = $0 }
            .foregroundColor(isFocused ? .srgGray16 : .srgGrayC7)
        }
        .buttonStyle(FlatButtonStyle(focused: isFocused))
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
    }
}

// MARK: Preview

struct SimpleButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SimpleButton(icon: .favorite, label: "Add to favorites", action: {})
            SimpleButton(icon: .favorite, accessibilityLabel: "Add to favorites", action: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
