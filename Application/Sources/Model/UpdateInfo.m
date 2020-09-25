//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UpdateInfo.h"

@import libextobjc;

@interface UpdateInfo ()

@property (nonatomic) UpdateType type;
@property (nonatomic, copy) NSString *reason;

@end

@implementation UpdateInfo

#pragma mark MTLJSONSerializing protocol

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    static NSDictionary *s_mapping;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_mapping = @{ @keypath(UpdateInfo.new, type) : @"type",
                       @keypath(UpdateInfo.new, reason) : @"text" };
    });
    return s_mapping;
}

#pragma mark Transformers

+ (NSValueTransformer *)typeJSONTransformer
{
    static NSValueTransformer *s_transformer;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{ @"None" : @(UpdateTypeNone),
                                                                                         @"Mandatory" : @(UpdateTypeMandatory),
                                                                                         @"Optional" : @(UpdateTypeOptional) }
                                                                         defaultValue:@(UpdateTypeNone)
                                                                  reverseDefaultValue:nil];
    });
    return s_transformer;
}

@end
