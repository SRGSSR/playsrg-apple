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
 *  Common accessibility metadata (with optionally inlined channel information).
 */
- (NSString *)play_accessibilityLabelWithChannel:(nullable SRGChannel *)channel;

@end

NS_ASSUME_NONNULL_END
