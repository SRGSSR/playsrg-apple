//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RadioChannel.h"

#import "PlayFirebaseConfiguration.h"

@interface RadioChannel ()

@property (nonatomic) BOOL homepageHidden;
@property (nonatomic) NSArray<NSNumber *> *homeSections;

@end

@implementation RadioChannel

#pragma Object lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary defaultHomeSections:(NSArray<NSNumber *> *)defaultHomeSections
{
    if (self = [super initWithDictionary:dictionary]) {
        id homeSections = dictionary[@"homeSections"];
        self.homeSections = [homeSections isKindOfClass:NSString.class] ? FirebaseConfigurationHomeSections(homeSections) : defaultHomeSections ?: @[];
        
        id homepageHidden = dictionary[@"homepageHidden"];
        if ([homepageHidden isKindOfClass:NSNumber.class]) {
            self.homepageHidden = [homepageHidden boolValue];
        }
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    return [self initWithDictionary:dictionary defaultHomeSections:@[]];
}

@end

UIImage *RadioChannelLogoImage(RadioChannel *radioChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@", radioChannel.resourceUid]] ?: [UIImage imageNamed:@"radioset"];
}

UIImage *RadioChannelLargeLogoImage(RadioChannel *radioChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@-large", radioChannel.resourceUid]] ?: [UIImage imageNamed:@"radioset-large"];
}

UIImage *RadioChannelLogoImageWithTraitCollection(RadioChannel *radioChannel, UITraitCollection *traitCollection)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@", radioChannel.resourceUid] inBundle:nil compatibleWithTraitCollection:traitCollection] ?: [UIImage imageNamed:@"radioset"];
}
