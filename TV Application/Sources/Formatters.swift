//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct DateFormatters {
    private static let relativeDateAndTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    static func formattedRelativeDateAndTime(for date: Date) -> String {
        return relativeDateAndTimeFormatter.string(from: date)
    }
    
    private static let relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    static func formattedRelativeDate(for date: Date) -> String {
        return relativeDateFormatter.string(from: date)
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
    
    private static let shortHourFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static func hours(for duration: TimeInterval) -> String {
        return Self.shortHourFormatter.string(from: max(duration, 60 * 60))!
    }
    
    private static let shortDayFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static func days(for duration: TimeInterval) -> String {
        return Self.shortDayFormatter.string(from: max(duration, 60 * 60 * 24))!
    }
}
