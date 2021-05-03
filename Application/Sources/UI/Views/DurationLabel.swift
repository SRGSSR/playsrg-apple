//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI



struct DurationLabel_Preview: PreviewProvider {
    static var previews: some View {
        DurationLabel(media: Mock.media())
            .padding()
            .background(Color.white)
            .previewLayout(.sizeThatFits)
    }
}
