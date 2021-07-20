//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// Borrowed from https://www.swiftbysundell.com/tips/swiftui-automatic-placeholders/

struct RedactingView<Input: View, Output: View>: View {
    let content: Input
    let modifier: (Input) -> Output
    
    @Environment(\.redactionReasons) private var reasons
    
    var body: some View {
        if reasons.isEmpty {
            content
        }
        else {
            modifier(content)
        }
    }
}

extension View {
    /// Call a modifier block when the receiver is redacted, allowing to further
    /// customize its behavior.
    func whenRedacted<T: View>(apply modifier: @escaping (Self) -> T) -> some View {
        return RedactingView(content: self, modifier: modifier)
    }
    
    /// Make the receiver redactable (hiding its content, even redactable one, and replacing
    /// it with a redacted rectangle of the same size).
    func redactable() -> some View {
        return whenRedacted { $0.hidden().background(Color(white: 1, opacity: 0.15)) }
    }
    
    /// Make the receiver unredactable (hidden when redacted).
    func unredactable() -> some View {
        return whenRedacted { $0.hidden() }
    }
    
    /// Make the receiver redacted when the provided argument is `nil`.
    func redactedIfNil(_ object: Any?) -> some View {
        return redacted(reason: object == nil ? .placeholder : .init())
    }
}
