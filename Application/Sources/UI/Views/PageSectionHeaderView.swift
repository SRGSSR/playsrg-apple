//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct PageSectionHeaderView: View {
    let section: PageModel.Section
    let pageTitle: String?
    
    var body: some View {
        if let pageTitle = pageTitle {
            Text(pageTitle)
                .srgFont(.H1)
                .foregroundColor(.white)
                .opacity(0.8)
        }
        VStack(alignment: .leading) {
            if let title = section.properties.title {
                Text(title)
                    .srgFont(.H2)
                    .lineLimit(1)
            }
            if let summary = section.properties.summary {
                Text(summary)
                    .srgFont(.subtitle)
                    .lineLimit(1)
                    .opacity(0.8)
            }
        }
        .opacity(0.8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
