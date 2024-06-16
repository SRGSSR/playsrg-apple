//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/**
 *  A simple generic stack which can either layout views horizontally or vertically. Provide common alignment
 *  options only.
 */
struct Stack<Content: View>: View {
    let direction: StackDirection
    let alignment: StackAlignment
    let spacing: CGFloat?

    @Binding private var content: () -> Content

    init(direction: StackDirection, alignment: StackAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.direction = direction
        self.alignment = alignment
        self.spacing = spacing
        _content = .constant(content)
    }

    private static func horizontalAlignment(for alignment: StackAlignment) -> HorizontalAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    private static func verticalAlignment(for alignment: StackAlignment) -> VerticalAlignment {
        switch alignment {
        case .leading:
            return .top
        case .center:
            return .center
        case .trailing:
            return .bottom
        }
    }

    var body: some View {
        if direction == .horizontal {
            HStack(alignment: Self.verticalAlignment(for: alignment), spacing: spacing, content: content)
        } else {
            VStack(alignment: Self.horizontalAlignment(for: alignment), spacing: spacing, content: content)
        }
    }
}

// MARK: Types

enum StackDirection {
    case vertical
    case horizontal
}

enum StackAlignment {
    case leading
    case center
    case trailing
}
