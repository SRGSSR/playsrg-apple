//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct TimelineNowView: View {
    var body: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(.white)
                .frame(width: 13, height: 8)
            Rectangle()
                .fill(.white)
                .frame(width: 1, height: .infinity)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.width / 2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

// MARK: Preview

struct TimelineNowView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineNowView()
            .previewLayout(.fixed(width: 40, height: 400))
    }
}
