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
            .background(focused ? Color.srgGray96 : Color.srgGray23)
            .cornerRadius(10)
            .scaleEffect(focused && !configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: focused)
#else
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? Color.srgGray4A : Color.srgGray23)
            .cornerRadius(LayoutStandardViewCornerRadius)
#endif
    }
}

@available(iOS, unavailable)
struct TextButtonStyle: ButtonStyle {
    let focused: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(focused ? Color(white: 1, opacity: 0.3) : Color.clear)
            .scaleEffect(focused && !configuration.isPressed ? 1.04 : 1)
            .animation(.easeOut(duration: 0.2), value: focused)
    }
}
