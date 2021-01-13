//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct LabeledButton: View {
    let icon: String
    let label: String
    let style: Style
    let action: () -> Void
    
    enum Style {
        case standard
        case small
        
        fileprivate var fontStyle: SRGFont.Style {
            switch self {
            case .small:
                return .overline
            default:
                return .button2
            }
        }
    }
    
    @State private var isFocused: Bool = false
    
    var body: some View {
        VStack {
            Button(action: action) {
                Image(icon)
                    .foregroundColor(isFocused ? .darkGray : .white)
                    .onFocusChange { isFocused = $0 }
                    .accessibilityElement()
                    .accessibilityLabel(label)
                    .accessibility(addTraits: .isButton)
            }
            Text(label)
                .srgFont(style.fontStyle)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(isFocused ? .white : .gray)
        }
        .frame(width: 130)
    }
}

struct LabeledButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LabeledButton(icon: "episodes-22", label: "Episodes", style: .standard, action: {})
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
                .previewDisplayName("Short label")
            
            LabeledButton(icon: "favorite-22", label: "Watch later", style: .standard, action: {})
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
                .previewDisplayName("Long label")
            
            LabeledButton(icon: "favorite-22", label: "Watch later", style: .small, action: {})
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
                .previewDisplayName("Small long label")
        }
    }
}
