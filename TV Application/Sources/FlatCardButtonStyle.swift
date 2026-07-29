//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  A flat card button style to replace the built-in CardButtonStyle which suffers from issues since
 *  tvOS 16, especially when used in heterogeneous cells displayed in a compositional layout.
 */
@available(iOS, unavailable)
struct FlatCardButtonStyle: ButtonStyle {
    let focused: Bool

    @State private var unfocusedSize: CGSize = .zero

    private var shadowColor: Color {
        focused ? Color(white: 0, opacity: 0.8) : .clear
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color(white: 1, opacity: 0.1))
            .cornerRadius(10)
            .scaleEffect(focused && !configuration.isPressed ? Self.focusedScaleFactor(for: unfocusedSize) : 1)
            .shadow(color: shadowColor, radius: 20, y: 20)
            .animation(.easeOut(duration: 0.2), value: focused)
            .readSize { size in
                unfocusedSize = size
            }
    }
}

struct TextButtonStyle: ButtonStyle {
    let focused: Bool

    @State private var unfocusedSize: CGSize = .zero

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(focused ? Color(white: 1, opacity: 0.3) : Color.clear)
            .scaleEffect(focused && !configuration.isPressed ? Self.focusedScaleFactor(for: unfocusedSize) : 1)
            .animation(.easeOut(duration: 0.2), value: focused)
            .readSize { size in
                unfocusedSize = size
            }
    }
}
