//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalytics

/**
 *  Return Play click event labels. Extra values needed.
 */
func analyticsClickEventLabels() -> SRGAnalyticsHiddenEventLabels {
    let labels = SRGAnalyticsHiddenEventLabels()
    labels.source = "2727"
    labels.type = "ClickEvent"
    
    return labels
}
