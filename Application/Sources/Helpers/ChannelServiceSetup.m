//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ChannelServiceSetup.h"

@interface ChannelServiceSetup ()

@property (nonatomic) SRGChannel *channel;
@property (nonatomic) SRGVendor vendor;
@property (nonatomic, copy) NSString *livestreamUid;

@end

@implementation ChannelServiceSetup

#pragma mark Object lifecycle

- (instancetype)initWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor livestreamUid:(NSString *)livestreamUid
{
    if (self = [super init]) {
        self.channel = channel;
        self.vendor = vendor;
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
    return [self.channel isEqual:otherSetup.channel] && self.vendor == otherSetup.vendor && [self.livestreamUid isEqualToString:otherSetup.livestreamUid];
}

- (NSUInteger)hash
{
    return [NSString stringWithFormat:@"%@_%@_%@_%@", self.channel.uid, @(self.channel.transmission), @(self.vendor), self.livestreamUid].hash;
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    return [[ChannelServiceSetup alloc] initWithChannel:self.channel vendor:self.vendor livestreamUid:self.livestreamUid];
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
