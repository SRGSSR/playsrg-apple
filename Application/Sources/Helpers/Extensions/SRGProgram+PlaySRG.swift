//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

extension SRGProgram {
    @objc func play_containsDate(_ date: Date) -> Bool {
        // Avoid potential crashes if data is incorrect
        let startDate = min(startDate, endDate)
        let endDate = max(self.startDate, endDate)

        return DateInterval(start: startDate, end: endDate).contains(date)
    }

    @objc func play_accessibilityLabel(with channel: SRGChannel?) -> String {
        var label = String(format: PlaySRGAccessibilityLocalizedString("From %1$@ to %2$@", comment: "Text providing program time information. First placeholder is the start time, second is the end time."), PlayAccessibilityTimeFromDate(startDate), PlayAccessibilityTimeFromDate(endDate))
        if let channel {
            label += " " + String(format: PlaySRGAccessibilityLocalizedString("on %@", comment: "Text providing a channel information. Placeholder is the channel on which it's broadcasted."), channel.title)
        }
        return label + ", " + title
    }
}
