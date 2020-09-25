//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RadioChannel.h"

#import "FirebaseConfiguration.h"

@interface RadioChannel ()

@property (nonatomic) NSArray<NSNumber *> *homeSections;

@end

@implementation RadioChannel

#pragma Object lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary defaultHomeSections:(NSArray<NSNumber *> *)defaultHomeSections
{
    if (self = [super initWithDictionary:dictionary]) {
        id homeSections = dictionary[@"homeSections"];
        self.homeSections = [homeSections isKindOfClass:NSString.class] ? FirebaseConfigurationHomeSections(homeSections) : defaultHomeSections;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    return [self initWithDictionary:dictionary defaultHomeSections:@[]];
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
