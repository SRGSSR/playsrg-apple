//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct LabeledButton: View {
    let icon: String
    let label: String
    let accessibilityLabel: String
    let action: () -> Void
    
    @State private var isFocused = false
    
    init(icon: String, label: String, accessibilityLabel: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.accessibilityLabel = accessibilityLabel ?? label
        self.action = action
    }
    
    var body: some View {
        VStack {
            Button(action: action) {
                Image(icon)
                    .frame(width: 68)
                    .foregroundColor(isFocused ? .darkGray : .white)
                    .onParentFocusChange { isFocused = $0 }
                    .accessibilityElement(label: accessibilityLabel, traits: .isButton)
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
            LabeledButton(icon: "episodes-22", label: "Episodes", action: {})
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
                .previewDisplayName("Short label")
            
            LabeledButton(icon: "favorite-22", label: "Watch later", action: {})
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
                .previewDisplayName("Long label")
        }
    }
}
