//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Standard duration formatters for a single unit.
 */
OBJC_EXPORT NSString *PlayFormattedMinutes(NSTimeInterval duration);
OBJC_EXPORT NSString *PlayFormattedHours(NSTimeInterval duration);
OBJC_EXPORT NSString *PlayFormattedDays(NSTimeInterval duration);

/**
 *  Short duration formatters for a single unit (minimum 1 unit).
 */
OBJC_EXPORT NSString *PlayShortFormattedMinutes(NSTimeInterval duration);
OBJC_EXPORT NSString *PlayShortFormattedHours(NSTimeInterval duration);
OBJC_EXPORT NSString *PlayShortFormattedDays(NSTimeInterval duration);

/**
 *  Formats a duration in a standard form, e.g. for use in duration labels.
 */
OBJC_EXPORT NSString *PlayFormattedDuration(NSTimeInterval duration);

/**
 *  Formats a duration in a human readable way, with explicit hours, minutes and seconds.
 */
OBJC_EXPORT NSString *PlayHumanReadableFormattedDuration(NSTimeInterval duration);

/**
 *  Formats a remaining time duration in hours or minutes (minimum 1 minute).
 */
OBJC_EXPORT NSString *PlayRemainingTimeFormattedDuration(NSTimeInterval duration);

NS_ASSUME_NONNULL_END
