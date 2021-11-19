//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct FlatButtonStyle: ButtonStyle {
    let focused: Bool
    
    func makeBody(configuration: Configuration) -> some View {
#if os(tvOS)
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(focused ? Color.srgGray33 : Color.srgGray23)
            .cornerRadius(5)
            .scaleEffect(focused && !configuration.isPressed ? 1.02 : 1)
            .animation(.default)
#else
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? Color.srgGray33 : Color.srgGray23)
            .cornerRadius(3)
#endif
    }
}

@available(iOS, unavailable)
struct TextButtonStyle: ButtonStyle {
    let focused: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(focused ? Color(UIColor(white: 1, alpha: 0.3)) : Color.clear)
            .scaleEffect(focused && !configuration.isPressed ? 1.02 : 1)
    }
}
