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
    func whenRedacted<T: View>(apply modifier: @escaping (Self) -> T) -> some View {
        RedactingView(content: self, modifier: modifier)
    }
}
