//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "OnboardingPage.h"

@import libextobjc;
@import SRGAppearance;

@interface OnboardingPage ()

@property (nonatomic, copy) NSString *uid;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *text;

@property (nonatomic) UIColor *color;

@end

@implementation OnboardingPage

#pragma mark MTLJSONSerializing protocol

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    static NSDictionary *s_mapping;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_mapping = @{ @keypath(OnboardingPage.new, uid) : @"uid",
                       @keypath(OnboardingPage.new, title) : @"title",
                       @keypath(OnboardingPage.new, text) : @"text",
                       @keypath(OnboardingPage.new, color) : @"color" };
    });
    return s_mapping;
}

#pragma mark Transformers

+ (NSValueTransformer *)colorJSONTransformer
{
    return SRGHexadecimalColorTransformer();
}

@end
