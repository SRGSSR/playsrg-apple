//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

enum StackDirection {
    case vertical
    case horizontal
}

/**
 *  A simple generic stack which can either layout views horizontally or vertically, but does not
 *  support alignment (centering only).
 */
struct Stack<Content: View>: View {
    let direction: StackDirection
    let spacing: CGFloat?
    private let content: () -> Content
    
    init(direction: StackDirection, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.direction = direction
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        if direction == .horizontal {
            HStack(spacing: spacing, content: content)
        }
        else {
            VStack(spacing: spacing, content: content)
        }
    }
}
