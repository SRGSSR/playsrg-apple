//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Onboarding.h"

#import "ApplicationConfiguration.h"

@import libextobjc;

@interface Onboarding ()

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *title;

@property (nonatomic) NSArray<OnboardingPage *> *pages;

@end

@implementation Onboarding

#pragma mark Class methods

+ (NSArray<Onboarding *> *)onboardings
{
    static dispatch_once_t s_onceToken;
    static NSArray<Onboarding *> *s_onboardings;
    dispatch_once(&s_onceToken, ^{
        NSString *filePath = [NSBundle.mainBundle pathForResource:@"Onboardings" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        
        id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if (! [JSON isKindOfClass:NSArray.class]) {
            s_onboardings = @[];
            return;
        }
        
        NSArray<NSString *> *hiddenOnboardingUids = ApplicationConfiguration.sharedApplicationConfiguration.hiddenOnboardingUids;
        NSArray<Onboarding *> *onboardings = [MTLJSONAdapter modelsOfClass:Onboarding.class fromJSONArray:JSON error:NULL] ?: @[];
        
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(Onboarding * _Nullable onboarding, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ! [hiddenOnboardingUids containsObject:onboarding.uid];
        }];
        s_onboardings = [onboardings filteredArrayUsingPredicate:predicate];
    });
    return s_onboardings;
}

#pragma mark Getters and setters

- (NSString *)iconName
{
    return [NSString stringWithFormat:@"%@_icon", self.uid];
}

#pragma mark MTLJSONSerializing protocol

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    static NSDictionary *s_mapping;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_mapping = @{ @keypath(Onboarding.new, uid) : @"uid",
                       @keypath(Onboarding.new, title) : @"title",
                       @keypath(Onboarding.new, pages) : @"pages" };
    });
    return s_mapping;
}

#pragma mark Transformers

+ (NSValueTransformer *)pagesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:OnboardingPage.class];
}

@end
