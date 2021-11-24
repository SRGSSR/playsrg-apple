//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

@interface SRGProgram (SRGPlay)

/**
 *  Returns `YES` iff the program is on air on the specified date.
 */
- (BOOL)play_containsDate:(NSDate *)date;

/**
 *  Common accessibility metadata.
 */
@property (nonatomic, copy) NSString *play_accessibilityLabel;

@end

NS_ASSUME_NONNULL_END
