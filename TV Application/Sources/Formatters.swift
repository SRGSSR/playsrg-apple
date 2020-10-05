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
    
    static func shortMinutes(for duration: TimeInterval) -> String {
        return Self.shortMinuteFormatter.string(from: max(duration, 60))!
    }
    
    private static let shortHourFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static func shortHours(for duration: TimeInterval) -> String {
        return Self.shortHourFormatter.string(from: max(duration, 60 * 60))!
    }
    
    private static let shortDayFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static func shortDays(for duration: TimeInterval) -> String {
        return Self.shortDayFormatter.string(from: max(duration, 60 * 60 * 24))!
    }
    
    private static let hourFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour]
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static func hours(for duration: TimeInterval) -> String {
        return Self.hourFormatter.string(from: max(duration, 60 * 60))!
    }
    
    private static let dayFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static func days(for duration: TimeInterval) -> String {
        return Self.dayFormatter.string(from: max(duration, 60 * 60 * 24))!
    }
}
