//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSDateFormatter (PlaySRG)

/**
 *  Absolute time formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_timeFormatter;

/**
 *  Relative date and time formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today.
 *
 * @discussion Use `PlayAccessibilityRelativeDateAndTimeFromDate` for accessibility-oriented formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeDateAndTimeFormatter;

/**
 *  Relative date formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeDateFormatter;

/**
 *  Short time formatting.
 *
 * @discussion Use `PlayAccessibilityShortTimeFromDate` for accessibility-oriented formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_shortTimeFormatter;

/**
 *  Formatter for URL date options.
 */
+ (NSDateFormatter *)play_URLOptionDateFormatter;

/**
 *  RFC 3339 date formatter.
 */
+ (NSDateFormatter *)play_rfc3339DateFormatter;

@end

NS_ASSUME_NONNULL_END
