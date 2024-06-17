//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

private struct FocusTracker<Content: View>: View {
    private let action: (Bool) -> Void
    @Binding private var content: () -> Content

    @Environment(\.isFocused) private var isFocused

    init(action: @escaping (Bool) -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        _content = .constant(content)
    }

    var body: some View {
        content()
            .onChange(of: isFocused) { action($0) }
    }
}

// MARK: Modifiers

extension View {
    func onParentFocusChange(perform action: @escaping (Bool) -> Void) -> some View {
        FocusTracker(action: action) {
            self
        }
    }
}
