//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RadioChannel.h"

@interface RadioChannel ()

@property (nonatomic) NSArray<NSNumber *> *homeSections;

@end

@implementation RadioChannel

#pragma Object lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super initWithDictionary:dictionary]) {
        self.homeSections = dictionary[@"homeSections"];
        if (! [self.homeSections isKindOfClass:NSArray.class] || self.homeSections.count == 0) {
            return nil;
        }
    }
    return self;
}

@end

UIImage *RadioChannelLogo22Image(RadioChannel *radioChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@-22", radioChannel.resourceUid]] ?: [UIImage imageNamed:@"radioset-22"];
}

UIImage *RadioChannelLogo32Image(RadioChannel *radioChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@-32", radioChannel.resourceUid]] ?: [UIImage imageNamed:@"radioset-32"];
}
