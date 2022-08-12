//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct NowArrowView: View {
    static let size = CGSize(width: 13, height: 8)
    
    var body: some View {
        Triangle()
            .fill(.white)
            .frame(width: Self.size.width, height: Self.size.height)
    }
    
    private struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.width / 2, y: rect.maxY))
            path.addLine(to: .zero)
            path.addLine(to: CGPoint(x: rect.maxX, y: 0))
            path.closeSubpath()
            return path
        }
    }
}

// MARK: Preview

struct NowArrowView_Previews: PreviewProvider {
    static var previews: some View {
        NowArrowView()
            .previewLayout(.fixed(width: 100, height: 100))
    }
}
