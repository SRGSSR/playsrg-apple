//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDateFormatter (PlaySRG)

/**
 *  Use absolute time formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_timeFormatter;

/**
 *  Use relative date and time formatting, i.e. displays today / yesterday for dates near today
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeDateAndTimeFormatter;

/**
 *  Use only relative date formatting, i.e. displays today / yesterday for dates near today
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeDateFormatter;

/**
 *  Use only short time formatting
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeTimeFormatter;

/**
 *  Same as `play_relativeDateAndTimeFormatter` but for accessibility
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeDateAndTimeAccessibilityFormatter;

/**
 *  Same as `play_relativeDateAndTimeFormatter` but for accessibility
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeDateAccessibilityFormatter;

/**
 *  Same as `play_relativeDateAndTimeFormatter` but for accessibility
 */
@property (class, nonatomic, readonly) NSDateFormatter *play_relativeTimeAccessibilityFormatter;

@end

NS_ASSUME_NONNULL_END
