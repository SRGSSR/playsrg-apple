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
 *
 *  @discussion Use `PlayAccessibilityTimeFromDate` for accessibility-oriented formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_timeFormatter;

/**
 *  Absolute short date formatting.
 *
 *  @discussion Use `PlayAccessibilityDateFromDate` for accessibility-oriented formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_shortDateFormatter;

/**
 *  Absolute date and time short formatting.
 *
 *  @discussion Use `PlayAccessibilityDateAndTimeFromDate` for accessibility-oriented formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_shortDateAndTimeFormatter;

/**
 *  Relative date and time formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today.
 *
 * @discussion Use `PlayAccessibilityRelativeDateAndTimeFromDate` for accessibility-oriented formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeDateAndTimeFormatter;

/**
 *  Relative date formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today, otherwise
 *  the date in a long format.
 *
 *  @discussion Use `PlayAccessibilityRelativeDateFromDate` for accessibility-oriented formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeDateFormatter;

/**
 *  Relative date formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today, otherwise
 *  the date in a full format.
 *
 *  @discussion Use `PlayAccessibilityRelativeDateFromDate` for accessibility-oriented formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeFullDateFormatter;

/**
 *  Relative date formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today, otherwise
 *  the date in a short format.
 *
 *  @discussion Use `PlayAccessibilityRelativeDateFromDate` for accessibility-oriented formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeShortDateFormatter;

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
