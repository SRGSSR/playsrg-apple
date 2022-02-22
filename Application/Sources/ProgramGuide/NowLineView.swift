//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-hug, v-exp
struct NowLineView: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.white)
                .frame(width: 1)
        }
    }
}

// MARK: Preview

struct NowLineView_Previews: PreviewProvider {
    static var previews: some View {
        NowLineView()
            .previewLayout(.fixed(width: 40, height: 400))
    }
}
