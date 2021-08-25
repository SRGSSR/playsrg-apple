//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "StoreReview.h"

#import "PlaySRG-Swift.h"

@import StoreKit;

@implementation StoreReview

#pragma mark Class methods

+ (void)requestReview
{
#if !defined(DEBUG) && !defined(NIGHTLY) && !defined(BETA)
    static NSString * const kRequestCountUserDefaultsKey = @"PlaySRGStoreReviewRequestCount";
    NSInteger requestCount = [NSUserDefaults.standardUserDefaults integerForKey:kRequestCountUserDefaultsKey] + 1;
    static const NSInteger kRequestCountThreshold = 50;
    if (requestCount >= kRequestCountThreshold) {
        UIWindowScene *windowScene = UIApplication.sharedApplication.mainWindowScene;
        [SKStoreReviewController requestReviewInScene:windowScene];
        requestCount = 0;
    }
    [NSUserDefaults.standardUserDefaults setInteger:requestCount forKey:kRequestCountUserDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
#endif
}
@end
