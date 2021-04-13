//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct PageSectionHeaderView: View {
    let section: PageModel.Section
    let pageTitle: String?
    
    @Environment(\.accessibilityEnabled) private var accessibilityEnabled
        
    private var accessibilityLabel: String {
        if let summary = section.properties.summary {
            return section.properties.accessibilityTitle + ", " + summary
        }
        else {
            return section.properties.accessibilityTitle
        }        
    }
    
    private var accessibilityHint: String {
        return section.properties.canOpenDetailPage ? PlaySRGAccessibilityLocalizedString("Shows all contents.", "Homepage header action hint") : ""
    }
    
    var body: some View {
        if let pageTitle = pageTitle {
            Text(pageTitle)
                .srgFont(.H1)
                .foregroundColor(.white)
                .opacity(0.8)
        }
        VStack(alignment: .leading) {
            if let title = accessibilityEnabled ? section.properties.accessibilityTitle : section.properties.title {
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
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibility(addTraits: .isHeader)
    }
}
