//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

extension DateFormatter {
    /**
     *  Absolute time formatting.
     *
     *  @discussion Use `PlayAccessibilityTimeFromDate` for accessibility-oriented formatting.
     */
    @objc static var play_time: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.srgTimeZone
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    /**
     *  Absolute short date formatting.
     *
     *  @discussion Use `PlayAccessibilityDateFromDate` for accessibility-oriented formatting.
     */
    @objc static var play_shortDate: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.srgTimeZone
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()
    
    /**
     *  Absolute date and time short formatting.
     *
     *  @discussion Use `PlayAccessibilityDateAndTimeFromDate` for accessibility-oriented formatting.
     */
    @objc static var play_shortDateAndTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.srgTimeZone
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    /**
     *  Relative date and time formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today.
     *
     * @discussion Use `PlayAccessibilityRelativeDateAndTimeFromDate` for accessibility-oriented formatting.
     */
    static var play_relativeDateAndTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.srgTimeZone
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    /**
     *  Relative date formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today, otherwise
     *  the date in a long format.
     *
     *  @discussion Use `PlayAccessibilityRelativeDateFromDate` for accessibility-oriented formatting.
     */
    static var play_relativeDate: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.srgTimeZone
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    /**
     *  Relative date formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today, otherwise
     *  the date in a full format.
     *
     *  @discussion Use `PlayAccessibilityRelativeDateFromDate` for accessibility-oriented formatting.
     */
    static var play_relativeFullDate: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.srgTimeZone
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    /**
     *  Relative date formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today, otherwise
     *  the date in a short format.
     *
     *  @discussion Use `PlayAccessibilityRelativeDateFromDate` for accessibility-oriented formatting.
     */
    static var play_relativeShortDate: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.srgTimeZone
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    /**
     *  Relative date formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today, otherwise
     *  the date in a short format and time in a short format.
     *
     *  @discussion Use `PlayAccessibilityRelativeDateFromDate` for accessibility-oriented formatting.
     */
    @objc static var play_relativeShortDateAndTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.srgTimeZone
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    /**
     *  ISO 8601 calendar date formatter.
     */
    @objc static var play_iso8601CalendarDate: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.srgTimeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    /**
     *  RFC 3339 date formatter.
     */
    @objc static var play_rfc3339Date: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.srgTimeZone
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter
    }()
}
