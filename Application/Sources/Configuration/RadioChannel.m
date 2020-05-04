//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RadioChannel.h"

@interface RadioChannel ()

@property (nonatomic, getter=hasDarkStatusBar) BOOL darkStatusBar;
@property (nonatomic, getter=isBadgeStrokeHidden) BOOL badgeStrokeHidden;
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
        
        id darkStatusBarValue = dictionary[@"hasDarkStatusBar"];
        if ([darkStatusBarValue isKindOfClass:NSNumber.class]) {
            self.darkStatusBar = [darkStatusBarValue boolValue];
        }
        
        id badgeStrokeHiddenValue = dictionary[@"badgeStrokeHidden"];
        if ([badgeStrokeHiddenValue isKindOfClass:NSNumber.class]) {
            self.badgeStrokeHidden = [badgeStrokeHiddenValue boolValue];
        }
    }
    return self;
}

@end

UIImage *RadioChannelBanner22Image(RadioChannel *radioChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"banner_%@-22", radioChannel.resourceUid]] ?: RadioChannelLogo22Image(radioChannel);
}

UIImage *RadioChannelLogo22Image(RadioChannel *radioChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@-22", radioChannel.resourceUid]] ?: [UIImage imageNamed:@"radioset-22"];
}

NSString *RadioChannelImageOverridePath(RadioChannel *radioChannel, NSString *type)
{
    NSString *overrideImageName = [NSString stringWithFormat:@"override_%@_%@", type, radioChannel.resourceUid];
    return [NSBundle.mainBundle pathForResource:overrideImageName ofType:@"pdf"];
}
