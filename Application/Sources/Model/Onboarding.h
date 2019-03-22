//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "OnboardingPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface Onboarding : MTLModel <MTLJSONSerializing>

@property (class, nonatomic, readonly) NSArray<Onboarding *> *onboardings;

@property (nonatomic, readonly, copy) NSString *uid;
@property (nonatomic, readonly, copy) NSString *title;

@property (nonatomic, readonly) NSArray<OnboardingPage *> *pages;

@end

NS_ASSUME_NONNULL_END
