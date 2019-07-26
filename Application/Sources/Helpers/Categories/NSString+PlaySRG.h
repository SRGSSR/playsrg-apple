//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (PlaySRG)

/**
 *  Use only short time formatting (hours and minutes).
 *
 * @discussion Same as `play_relativeTimeFormatter` in `NSDateFormatter"PlaySRG.h` but for accessibility.
 */
+ (NSString *)play_relativeTimeAccessibilityStringFromDate:(NSDate *)date;

/**
 *  Return the receiver with the first letter changed to uppercase (does not alter the other letters).
 */
@property (nonatomic, readonly, copy) NSString *play_localizedUppercaseFirstLetterString;

@end

NS_ASSUME_NONNULL_END
