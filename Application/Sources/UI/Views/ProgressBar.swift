//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color(white: 1, opacity: 0.3)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                Color.srgLightRed
                    .frame(width: geometry.size.width * CGFloat(value), height: geometry.size.height)
            }
        }
    }

    init(value: Double) {
        self.value = value.clamped(to: 0 ... 1)
    }
}

// MARK: Preview

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProgressBar(value: 0)
            ProgressBar(value: 0.6)
            ProgressBar(value: 1)
        }
        .frame(width: 400, height: 2)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
