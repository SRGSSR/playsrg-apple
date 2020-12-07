//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

fileprivate struct FocusTracker: View {
    let action: (Bool) -> Void
    
    @Environment(\.isFocused) private var isFocused: Bool
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .onChange(of: isFocused) { action($0) }
    }
}

extension View {
    /**
     *  Apply modifier on a view wrapped in a focusable context. The provided action block will be called
     *  each time a focus change is detected. This is useful to have parent or sibling views apply changes
     *  due to one of their children getting the focus.
     */
    func onFocusChange(perform action: @escaping (Bool) -> Void) -> some View {
        self.background(FocusTracker(action: action))
    }
}
