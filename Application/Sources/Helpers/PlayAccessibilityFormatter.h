//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Formats a relative date and time, i.e. returns today / yesterday / tomorrow / ... for dates near today, in a human
 *  readable way suited for accessibilty.
 *
 *  @discussion Similar to `+[NSDateFormatter play_relativeDateAndTimeFormatter]`, but for accessibility purposes.
 */
OBJC_EXPORT NSString *PlayAccessibilityRelativeDateAndTimeFromDate(NSDate *date);

/**
 *  Formats time (hours and minutes) in a human readable way suited for accessibilty.
 *
 *  @discussion Similar to `NSDateFormatter.play_timeFormatter`, but for accessibility purposes.
 */
OBJC_EXPORT NSString *PlayAccessibilityTimeFromDate(NSDate *date);

NS_ASSUME_NONNULL_END
