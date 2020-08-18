//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (PlaySRG)

/**
 *  Return the receiver with the first letter changed to uppercase (does not alter the other letters).
 */
@property (nonatomic, readonly, copy) NSString *play_localizedUppercaseFirstLetterString;

/**
 *  Calculate the MD5 hash.
 */
@property (nonatomic, readonly, copy) NSString *play_md5hash;

@end

NS_ASSUME_NONNULL_END
