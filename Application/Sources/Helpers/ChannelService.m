//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ChannelService.h"

#import "SmartTimer.h"

#import <CoconutKit/CoconutKit.h>
#import <FXReachability/FXReachability.h>
#import <libextobjc/libextobjc.h>

NSString * const ChannelServiceDidUpdateChannelsNotification = @"ChannelServiceDidUpdateChannelsNotification";

@interface ChannelService ()

@property (nonatomic) NSMutableDictionary<NSString *, NSMutableDictionary<NSValue *, ChannelServiceUpdateBlock> *> *registrations;
@property (nonatomic) NSMutableDictionary<NSString *, SRGMedia *> *medias;

// Cache channels. This cache is never invalidated, but its data is likely rarely to be staled as it is regularly updated. Cached
// data is used to return existing channel information as fast as possible, and when errors have been encountered.
@property (nonatomic) NSMutableDictionary<NSString *, SRGChannel *> *channels;

@property (nonatomic) SmartTimer *updateTimer;
@property (nonatomic) SRGRequestQueue *requestQueue;

@end

@implementation ChannelService

#pragma mark Class methods

+ (ChannelService *)sharedService
{
    static dispatch_once_t s_onceToken;
    static ChannelService *s_sharedService;
    dispatch_once(&s_onceToken, ^{
        s_sharedService = [[ChannelService alloc] init];
    });
    return s_sharedService;
}

+ (NSString *)channelKeyWithMedia:(SRGMedia *)media
{
    return [NSString stringWithFormat:@"%@;%@;%@", @(media.channel.transmission), media.channel.uid, media.uid];
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.registrations = [NSMutableDictionary dictionary];
        self.medias = [NSMutableDictionary dictionary];
        self.channels = [NSMutableDictionary dictionary];
        
        @weakify(self)
        self.updateTimer = [SmartTimer timerWithTimeInterval:30. repeats:YES background:NO queue:NULL block:^{
            @strongify(self)
            [self updateChannels];
        }];
        [self updateChannels];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(reachabilityDidChange:)
                                                   name:FXReachabilityStatusDidChangeNotification
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    self.updateTimer = nil;
}

#pragma mark Getters and setters

- (void)setUpdateTimer:(SmartTimer *)updateTimer
{
    [_updateTimer invalidate];
    _updateTimer = updateTimer;
    [updateTimer resume];
}

#pragma mark Registration

- (void)registerObserver:(id)observer forChannelUpdatesWithMedia:(SRGMedia *)media block:(ChannelServiceUpdateBlock)block
{
    NSString *channelKey = [ChannelService channelKeyWithMedia:media];
    NSMutableDictionary<NSValue *, ChannelServiceUpdateBlock> *channelRegistrations = self.registrations[channelKey];
    if (! channelRegistrations) {
        channelRegistrations = [NSMutableDictionary dictionary];
        self.registrations[channelKey] = channelRegistrations;
    }
    
    NSValue *observerKey = [NSValue valueWithNonretainedObject:observer];
    channelRegistrations[observerKey] = block;
    
    // Return data immediately available from the cache, but still trigger an update
    SRGChannel *channel = self.channels[channelKey];
    if (channel) {
        block(channel);
    }
    
    // Only force an update the first time a media is added. Other updates will occur perodically afterwards.
    if (! self.medias[channelKey]) {
        [self updateChannelWithMedia:media];
    }
    
    self.medias[channelKey] = media;
}

- (void)unregisterObserver:(id)observer forMedia:(SRGMedia *)media
{
    NSString *channelKey = [ChannelService channelKeyWithMedia:media];
    NSMutableDictionary<NSValue *, ChannelServiceUpdateBlock> *channelRegistrations = self.registrations[channelKey];
    if (! channelRegistrations) {
        return;
    }
    
    NSValue *observerKey = [NSValue valueWithNonretainedObject:observer];
    [channelRegistrations removeObjectForKey:observerKey];
    
    // If no registration exists for a channel anymore, remove it from the channel retrieval service. Cached channel
    // data is not discarded, though (if there is a single observer regularly registering and unregistering, like
    // a collection view cell, not clearing the cache ensures channel information is readily available when registering)
    if (channelRegistrations.count == 0) {
        self.registrations[channelKey] = nil;
        self.medias[channelKey] = nil;
    }
}

#pragma mark Data retrieval

- (void)updateChannelWithMedia:(SRGMedia *)media
{
    @weakify(self)
    SRGChannelCompletionBlock completionBlock = ^(SRGChannel * _Nullable channel, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        @strongify(self)
        
        NSString *channelKey = [ChannelService channelKeyWithMedia:media];
        if (channel) {
            self.channels[channelKey] = channel;
        }
        
        NSMutableDictionary<NSValue *, ChannelServiceUpdateBlock> *channelRegistrations = self.registrations[channelKey];
        for (ChannelServiceUpdateBlock updateBlock in channelRegistrations.allValues) {
            updateBlock(self.channels[channelKey]);
        }
    };
    
    SRGRequest *request = nil;
    if (media.channel.transmission == SRGTransmissionRadio) {
        if (media.vendor == SRGVendorSRF && ! [media.uid isEqualToString:media.channel.uid]) {
            request = [SRGDataProvider.currentDataProvider radioChannelForVendor:media.vendor withUid:media.channel.uid livestreamUid:media.uid completionBlock:completionBlock];
        }
        else {
            request = [SRGDataProvider.currentDataProvider radioChannelForVendor:media.vendor withUid:media.channel.uid livestreamUid:nil completionBlock:completionBlock];
        }
    }
    else {
        request = [SRGDataProvider.currentDataProvider tvChannelForVendor:media.vendor withUid:media.channel.uid completionBlock:completionBlock];
    }
    [self.requestQueue addRequest:request resume:YES];
}

- (void)updateChannels
{
    self.requestQueue = [[SRGRequestQueue alloc] initWithStateChangeBlock:^(BOOL finished, NSError * _Nullable error) {
        if (finished && ! error) {
            [NSNotificationCenter.defaultCenter postNotificationName:ChannelServiceDidUpdateChannelsNotification object:self];
        }
    }];
    
    for (SRGMedia *media in self.medias.allValues) {
        [self updateChannelWithMedia:media];
    }
}

#pragma mark Notifications

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if ([FXReachability sharedInstance].reachable) {
        [self updateChannels];
    }
}

@end
