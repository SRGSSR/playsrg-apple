//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct ExpandingButton: View, PrimaryColorSettable, PrimaryFocusedColorSettable {
    private let icon: ImageResource?
    private let label: String?
    private let accessibilityLabel: String
    private let accessibilityHint: String?
    private let action: () -> Void

    var primaryColor: Color = .srgGrayD2
    var primaryFocusedColor: Color = .srgGray16

    @State private var isFocused = false

    init(icon: ImageResource, label: String, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.accessibilityLabel = accessibilityLabel ?? label
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    init(label: String, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        icon = nil
        self.label = label
        self.accessibilityLabel = accessibilityLabel ?? label
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    init(icon: ImageResource, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        label = nil
        self.accessibilityLabel = accessibilityLabel ?? ""
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(icon)
                }
                if let label {
                    Text(label)
                        .srgFont(.button)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
            }
            .onParentFocusChange { isFocused = $0 }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(isFocused ? primaryFocusedColor : primaryColor)
        }
        .buttonStyle(FlatButtonStyle(focused: isFocused))
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
    }
}

// MARK: Preview

struct ExpandingButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExpandingButton(icon: .watchLater, label: "Later", action: {})
                .padding()
                .previewLayout(.fixed(width: 240, height: 120))
            ExpandingButton(icon: .watchLater, label: "Later", action: {})
                .padding()
                .previewLayout(.fixed(width: 240, height: 120))
            ExpandingButton(label: "Later", action: {})
                .padding()
                .previewLayout(.fixed(width: 120, height: 120))
            ExpandingButton(icon: .watchLater, action: {})
                .padding()
                .previewLayout(.fixed(width: 120, height: 120))
            ExpandingButton(label: "White foreground", action: {})
                .primaryColor(.white)
                .padding()
                .previewLayout(.fixed(width: 240, height: 120))
        }
    }
}
