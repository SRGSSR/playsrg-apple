//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

/// Behavior: h-exp, v-exp
struct ExpandedButton: View {
    let icon: String?
    let label: String
    let accessibilityLabel: String
    let accessibilityHint: String?
    let action: () -> Void
        
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
        .foregroundColor(.srgGrayC7)
        .background(Color.srgGray23)
        .cornerRadius(LayoutStandardViewCornerRadius)
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
    }
}

struct ExpandedButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExpandedButton(icon: "a_to_z", label: "A to Z", action: {})
                .padding()
                .previewLayout(.fixed(width: 240, height: 120))
            ExpandedButton(icon: "a_to_z", label: "A to Z", action: {})
                .padding()
                .previewLayout(.fixed(width: 120, height: 60))
            ExpandedButton(label: "A to Z", action: {})
                .padding()
                .previewLayout(.fixed(width: 120, height: 60))
        }
    }
}
