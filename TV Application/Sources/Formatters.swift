//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct DateFormatters {
    private static let timeAndDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    static func dateAndTime(for date: Date) -> String {
        return timeAndDateFormatter.string(from: date)
    }
}

struct DurationFormatters {
    private static let shortMinuteFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static func minutes(for duration: TimeInterval) -> String {
        return Self.shortMinuteFormatter.string(from: max(duration, 60))!
    }
}
