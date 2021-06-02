//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

private struct FocusTracker<Content: View>: View {
    private let action: (Bool) -> Void
    private let content: () -> Content
    
    @Environment(\.isFocused) private var isFocused: Bool
    
    init(action: @escaping (Bool) -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
    
    var body: some View {
        self.content()
            .onChange(of: isFocused) { action($0) }
    }
}

extension View {
    func onParentFocusChange(perform action: @escaping (Bool) -> Void) -> some View {
        FocusTracker(action: action) {
            self
        }
    }
}
