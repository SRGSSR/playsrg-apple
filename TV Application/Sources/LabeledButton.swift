//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct LabeledButton: View {
    let icon: String
    let label: String
    let accessibilityLabel: String?
    let action: () -> Void
    
    @State private var isFocused: Bool = false
    
    var body: some View {
        VStack {
            Button(action: action) {
                Image(icon)
                    .frame(width: 68)
                    .foregroundColor(isFocused ? .darkGray : .white)
                    .onFocusChange { isFocused = $0 }
                    .accessibilityElement()
                    .accessibilityLabel(accessibilityLabel ?? label)
                    .accessibility(addTraits: .isButton)
            }
            Text(label)
                .srgFont(.button2)
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
            LabeledButton(icon: "episodes-22", label: "Episodes", accessibilityLabel: nil, action: {})
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
                .previewDisplayName("Short label")
            
            LabeledButton(icon: "favorite-22", label: "Watch later", accessibilityLabel: nil, action: {})
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
                .previewDisplayName("Long label")
        }
    }
}
