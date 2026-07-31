//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct FlatButtonStyle: ButtonStyle {
    let focused: Bool
    let noPadding: Bool

    init(focused: Bool, noPadding: Bool = false) {
        self.focused = focused
        self.noPadding = noPadding
    }

    #if os(tvOS)
        @State private var unfocusedSize: CGSize = .zero
    #endif

    func makeBody(configuration: Configuration) -> some View {
        #if os(tvOS)
            configuration.label
                .padding(.horizontal, noPadding ? 0 : 16)
                .padding(.vertical, noPadding ? 0 : 12)
                .background(focused ? Color.srgGray96 : Color.srgGray23)
                .cornerRadius(10)
                .scaleEffect(focused && !configuration.isPressed ? Self.focusedScaleFactor(for: unfocusedSize) : 1)
                .animation(.easeOut(duration: 0.2), value: focused)
                .readSize { size in
                    unfocusedSize = size
                }
        #else
            configuration.label
                .padding(.horizontal, noPadding ? 0 : 10)
                .padding(.vertical, noPadding ? 0 : 8)
                .background(configuration.isPressed ? Color.srgGray4A : Color.srgGray23)
                .cornerRadius(LayoutStandardViewCornerRadius)
        #endif
    }
}
