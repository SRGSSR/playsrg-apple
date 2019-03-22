//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGDataProvider (PlaySRG)

/**
 *  Increase the specified activity type from 1 unit for the specified subdivision.
 *
 *  @return A request to be resumed if the activity type can be associated with a social count, `nil` otherwise.
 */
- (nullable SRGRequest *)play_increaseSocialCountForActivityType:(UIActivityType)activityType
                                                     subdivision:(SRGSubdivision *)subdivision
                                             withCompletionBlock:(SRGSocialCountOverviewCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END

