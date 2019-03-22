//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TVChannel.h"

#import "UIColor+PlaySRG.h"

@interface TVChannel ()

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *resourceUid;      // Local unique identifier for referencing resources in a common way

@end

@implementation TVChannel

#pragma Object lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.uid = dictionary[@"uid"];
        if (! [self.uid isKindOfClass:NSString.class]) {
            return nil;
        }
        
        self.name = dictionary[@"name"];
        if (! [self.name isKindOfClass:NSString.class]) {
            return nil;
        }
        
        self.resourceUid = dictionary[@"resourceUid"];
        if (! [self.resourceUid isKindOfClass:NSString.class]) {
            return nil;
        }
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithDictionary:@{}];
}

#pragma mark - Object identity

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (! [object isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.uid isEqualToString:[object uid]];
}

- (NSUInteger)hash
{
    return self.uid.hash;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; uid = %@; name = %@>",
            self.class,
            self,
            self.uid,
            self.name];
}

@end

UIImage *TVChannelBanner22Image(TVChannel *tvChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"banner_%@-22", tvChannel.resourceUid]] ?: [UIImage imageNamed:@"tv-22"];
}

NSString *TVChannelImageOverridePath(TVChannel *tvChannel, NSString *type)
{
    NSString *overrideImageName = [NSString stringWithFormat:@"override_%@_%@", type, tvChannel.resourceUid];
    return [NSBundle.mainBundle pathForResource:overrideImageName ofType:@"pdf"];
}
