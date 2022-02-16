//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct DayNavigationView: View {
    static let width: CGFloat = 50
    
    enum Direction {
        case forward
        case backward
    }
    
    let direction: Direction
    
    var body: some View {
        Button(action: action) {
            Color.red
        }
    }
    
    private func action() {
        print("--> change to sibling day")
    }
}

// MARK: Preview

struct DayNavigationViewPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            DayNavigationView(direction: .backward)
            DayNavigationView(direction: .forward)
        }
        .previewLayout(.fixed(width: DayNavigationView.width, height: 200))
    }
}
