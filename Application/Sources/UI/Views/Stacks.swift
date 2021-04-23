//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

enum StackLayout {
    case vertical
    case horizontal
}

/**
 *  A simple generic stack which can either layout views horizontally or vertically, but does not
 *  support alignment (centering only).
 */
struct Stack<Content: View>: View {
    let layout: StackLayout
    let spacing: CGFloat?
    private let content: () -> Content
    
    init(layout: StackLayout, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.layout = layout
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        if layout == .horizontal {
            HStack(spacing: spacing, content: content)
        }
        else {
            VStack(spacing: spacing, content: content)
        }
    }
}
