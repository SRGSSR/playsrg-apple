//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

@interface StoreReview : NSObject

/**
 *  Gracefully request for an AppStore review.
 *
 *  @see `SKStoreReviewController` documentation for more information.
 */
+ (void)requestReview;

@end
