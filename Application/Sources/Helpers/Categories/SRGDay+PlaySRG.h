//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProvider;

NS_ASSUME_NONNULL_BEGIN

@interface SRGDay (PlaySRG)

/*
 *  Returns `YES` if the receiver is between (included) `fromDay` and `toDay`.
 */
- (BOOL)play_isBetweenDay:(SRGDay *)fromDay andDay:(SRGDay *)toDay;

@end

NS_ASSUME_NONNULL_END
