//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderNetwork;

NS_ASSUME_NONNULL_BEGIN

@interface SRGDataProvider (PlaySRG)

/**
 *  Increase the specified activity type from 1 unit for the specified URN with associated event data.
 *
 *  @return A request to be resumed if the activity type can be associated with a social count, `nil` otherwise.
 */
- (nullable SRGRequest *)play_increaseSocialCountForActivityType:(UIActivityType)activityType
                                                             URN:(NSString *)URN
                                                           event:(NSString *)event
                                             withCompletionBlock:(SRGSocialCountOverviewCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
