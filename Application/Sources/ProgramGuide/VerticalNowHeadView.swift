//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct VerticalNowArrowView: View {
    static let width: CGFloat = 13
    static let headerHeight: CGFloat = 8
    
    var body: some View {
        Triangle()
            .fill(.white)
            .frame(width: Self.width, height: Self.headerHeight)
    }
    
    private struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.width / 2, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: 0))
            path.closeSubpath()
            return path
        }
    }
}

// MARK: Preview

struct VerticalNowArrowView_Previews: PreviewProvider {
    static var previews: some View {
        VerticalNowArrowView()
            .previewLayout(.fixed(width: 100, height: 100))
    }
}
