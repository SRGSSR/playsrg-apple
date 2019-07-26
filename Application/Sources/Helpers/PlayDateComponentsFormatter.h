//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Formats a duration in a standard form, e.g. for use in duration labels.
 */
OBJC_EXPORT NSString *PlayFormattedDuration(NSTimeInterval duration);

/**
 *  Formats a duration in a human readable way, with explicit hours, minutes and seconds.
 */
OBJC_EXPORT NSString *PlayHumanReadableFormattedDuration(NSTimeInterval duration);

/**
 *  Formats a duration in a compact form, only telling number of days or hours.
 */
OBJC_EXPORT NSString *PlayShortFormattedDuration(NSTimeInterval duration);

/**
 *  Formats a relative date and time, i.e. displays today / yesterday for dates near today in a human readable way for accessibilty.
 *
 *  @discussion Same as `play_relativeDateAndTimeFormatter` in `NSDateFormatter"PlaySRG.h` but for accessibility.
 */
OBJC_EXPORT NSString *PlayRelativeDateAndTimeAccessibilityDate(NSDate *date);

/**
 *  Formats only short time (hours and minutes) in a human readable way for accessibilty.
 *
 *  @discussion Same as `play_relativeTimeFormatter` in `NSDateFormatter"PlaySRG.h` but for accessibility.
 */
OBJC_EXPORT NSString *PlayRelativeTimeAccessibilityDate(NSDate *date);


NS_ASSUME_NONNULL_END
