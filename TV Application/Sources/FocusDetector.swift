//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

fileprivate struct FocusDetector: View {
    fileprivate struct FocusedKey: PreferenceKey {
        static var defaultValue: Bool = false
        
        static func reduce(value: inout Bool, nextValue: () -> Bool) {}
    }
    
    @Environment(\.isFocused) private var isFocused: Bool
    
    var body: some View {
        Color.clear
            .preference(key: FocusedKey.self, value: isFocused)
    }
}

extension View {
    func reportFocusChanges() -> some View {
        self.background(FocusDetector())
    }
    
    func onFocusChange(perform action: @escaping (Bool) -> Void) -> some View {
        onPreferenceChange(FocusDetector.FocusedKey.self, perform: action)
    }
}
