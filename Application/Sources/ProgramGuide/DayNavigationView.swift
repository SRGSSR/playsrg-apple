//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: Contract

@objc protocol DayNavigationViewActions: AnyObject {
    func navigateForward()
    func navigateBackward()
}

// MARK: View

/// Behavior: h-exp, v-exp
struct DayNavigationView: View {
    enum Direction: Int {
        case forward
        case backward
    }
    
    let direction: Direction
    
    @FirstResponder private var firstResponder
    
    static let width: CGFloat = 50
    
    var body: some View {
        Button(action: action) {
            Color.red
        }
        .responderChain(from: firstResponder)
    }
    
    private func action() {
        switch direction {
        case .forward:
            firstResponder.sendAction(#selector(DayNavigationViewActions.navigateForward))
        case .backward:
            firstResponder.sendAction(#selector(DayNavigationViewActions.navigateBackward))
        }
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
