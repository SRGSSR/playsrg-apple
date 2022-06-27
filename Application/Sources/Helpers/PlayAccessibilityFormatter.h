//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Formats a date in a human readable way suited for accessibility.
 */
OBJC_EXPORT NSString *PlayAccessibilityDateFromDate(NSDate *date);

/**
 *  Formats a relative date, i.e. returns today / yesterday / tomorrow / ... for dates near today, in a human readable
 *  way suited for accessibility.
 */
OBJC_EXPORT NSString *PlayAccessibilityRelativeDateFromDate(NSDate *date);

/**
 *  Formats a date and time in a human readable way suited for accessibility.
 */
OBJC_EXPORT NSString *PlayAccessibilityDateAndTimeFromDate(NSDate *date);

/**
 *  Formats a relative date and time, i.e. returns today / yesterday / tomorrow / ... for dates near today, as well as
 *  the time, in a human readable way suited for accessibility.
 */
OBJC_EXPORT NSString *PlayAccessibilityRelativeDateAndTimeFromDate(NSDate *date);

/**
 *  Formats time (hours and minutes) in a human readable way suited for accessibility.
 */
OBJC_EXPORT NSString *PlayAccessibilityTimeFromDate(NSDate *date);

/**
 *  Formats a number in a human readable way suited for accessibility.
 */
OBJC_EXPORT NSString *PlayAccessibilityNumberFormatter(NSNumber *number);

NS_ASSUME_NONNULL_END
