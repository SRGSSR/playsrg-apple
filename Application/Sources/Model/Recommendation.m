//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Recommendation.h"

@import libextobjc;

@interface Recommendation ()

@property (nonatomic) NSString *recommendationUid;
@property (nonatomic) NSArray<NSString *>* URNs;

@end

@implementation Recommendation

#pragma mark MTLJSONSerializing protocol

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    static NSDictionary *s_mapping;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_mapping = @{ @keypath(Recommendation.new, recommendationUid) : @"recommendationId",
                       @keypath(Recommendation.new, URNs) : @"urns" };
    });
    return s_mapping;
}
@end
