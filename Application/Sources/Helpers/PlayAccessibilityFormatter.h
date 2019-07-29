//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Formats a relative date and time, i.e. returns today / yesterday for dates near today in a human readable way for accessibilty.
 *
 *  @discussion Same as `+[NSDateFormatter play_relativeDateAndTimeFormatter]`, but for accessibility purposes.
 */
OBJC_EXPORT NSString *PlayAccessibilityRelativeDateAndTime(NSDate *date);

/**
 *  Formats only short time (hours and minutes) in a human readable way for accessibilty.
 *
 *  @discussion Same as `+[NSDateFormatter play_relativeTimeFormatter]`, but for accessibility purposes.
 */
OBJC_EXPORT NSString *PlayAccessibilityRelativeTime(NSDate *date);

NS_ASSUME_NONNULL_END
