//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Formats a relative date and time, i.e. returns today / yesterday / tomorrow / ... for dates near today, in a human
 *  readable way suited for accessibilty.
 *
 *  @discussion Similar to `+[NSDateFormatter play_relativeDateAndTimeFormatter]`, but for accessibility purposes.
 */
OBJC_EXPORT NSString *PlayAccessibilityRelativeDateAndTimeFromDate(NSDate *date);

/**
 *  Formats only short time (hours and minutes) in a human readable way suited for accessibilty.
 *
 *  @discussion Similar to `+[NSDateFormatter play_shortTimeFormatter]`, but for accessibility purposes.
 */
OBJC_EXPORT NSString *PlayAccessibilityShortTimeFromDate(NSDate *date);

NS_ASSUME_NONNULL_END
