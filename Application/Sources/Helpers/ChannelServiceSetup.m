//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ChannelServiceSetup.h"

@interface ChannelServiceSetup ()

@property (nonatomic) SRGChannel *channel;
@property (nonatomic, copy) NSString *livestreamUid;

@end

@implementation ChannelServiceSetup

#pragma mark Object lifecycle

- (instancetype)initWithChannel:(SRGChannel *)channel livestreamUid:(NSString *)livestreamUid
{
    if (self = [super init]) {
        self.channel = channel;
        self.livestreamUid = livestreamUid;
    }
    return self;
}

#pragma mark Equality

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:self.class]) {
        return NO;
    }
    
    ChannelServiceSetup *otherSetup = object;
    return [self.channel isEqual:otherSetup.channel] && [self.livestreamUid isEqualToString:otherSetup.livestreamUid];
}

- (NSUInteger)hash
{
    return [NSString stringWithFormat:@"%@_%@", self.channel.URN, self.livestreamUid].hash;
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    return [[ChannelServiceSetup alloc] initWithChannel:self.channel livestreamUid:self.livestreamUid];
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; channel = %@; livestreamUid = %@>",
            self.class,
            self,
            self.channel,
            self.livestreamUid];
}

@end
