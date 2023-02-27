//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/// Behavior: h-exp, v-hug
struct Handle: View {
    let action: (() -> Void)
    
    var body: some View {
        Button {
            action()
        }  label: {
            // Use similar values as Aiolos `ResizeHandle`.
            GeometryReader { geometry in
                ZStack {
                    Grabber()
                        .position(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0 - 0.5)
                }
            }
        }
        .frame(height: 20)
    }
    
    /// Behavior: h-hug, v-hug
    private struct Grabber: View {
        private let grabberHeight = 5.0
        private let grabberWidth = 38.0
        
        var body: some View {
            RoundedRectangle(cornerRadius: grabberHeight / 2)
                .frame(width: grabberWidth, height: grabberHeight)
                .foregroundColor(.srgGrayC7)
        }
    }
}

struct Handle_Previews: PreviewProvider {
    static var previews: some View {
        Handle(action: {})
            .frame(width: 375)
            .previewLayout(.sizeThatFits)
    }
}
