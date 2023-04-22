//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ChannelService.h"

#import "ChannelServiceSetup.h"
#import "ForegroundTimer.h"
#import "Reachability.h"
#import "PlaySRG-Swift.h"

@import libextobjc;
@import SRGDataProviderNetwork;

@interface ChannelService ()

@property (nonatomic) NSMutableDictionary<ChannelServiceSetup *, NSMutableDictionary<NSString *, ChannelServiceUpdateBlock> *> *registrations;

// Cache channels. This cache is never invalidated, but its data is likely rarely to be staled as it is regularly updated. Cached
// data is used to return existing channel information as fast as possible, and when errors have been encountered.
@property (nonatomic) NSMutableDictionary<ChannelServiceSetup *, SRGProgramComposition *> *programCompositions;

@property (nonatomic) ForegroundTimer *updateTimer;
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

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.registrations = [NSMutableDictionary dictionary];
        self.programCompositions = [NSMutableDictionary dictionary];
        
        @weakify(self)
        self.updateTimer = [ForegroundTimer timerWithTimeInterval:30. repeats:YES block:^(ForegroundTimer * _Nonnull timer) {
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

- (void)setUpdateTimer:(ForegroundTimer *)updateTimer
{
    [_updateTimer invalidate];
    _updateTimer = updateTimer;
}

#pragma mark Registration

- (id)addObserverForUpdatesWithChannel:(SRGChannel *)channel livestreamUid:(NSString *)livestreamUid block:(ChannelServiceUpdateBlock)block
{
    BOOL channelAdded = NO;
    
    ChannelServiceSetup *setup = [[ChannelServiceSetup alloc] initWithChannel:channel livestreamUid:livestreamUid];
    NSMutableDictionary<NSString *, ChannelServiceUpdateBlock> *channelRegistrations = self.registrations[setup];
    if (! channelRegistrations) {
        channelRegistrations = [NSMutableDictionary dictionary];
        self.registrations[setup] = channelRegistrations;
        channelAdded = YES;
    }
    
    NSString *identifier = NSUUID.UUID.UUIDString;
    channelRegistrations[identifier] = block;
    
    // Return data immediately available from the cache
    SRGProgramComposition *programComposition = self.programCompositions[setup];
    if (programComposition) {
        block(programComposition);
    }
    
    // Trigger an update the first time a channel is added. Other updates will occur perodically afterwards.
    if (channelAdded) {
        [self refreshWithSetup:setup];
    }
    
    return identifier;
}

- (void)removeObserver:(id)observer
{
    if (! observer) {
        return;
    }
    
    for (NSMutableDictionary<NSString *, ChannelServiceUpdateBlock> *channelRegistrations in self.registrations.allValues) {
        [channelRegistrations removeObjectForKey:observer];
    }
    
    // Keep registered channels for the lifetime of the app, do not remove associated entries (otherwise we might
    // remove and add channels repeatedly, triggering an update each time)
}

#pragma mark Data retrieval

- (void)refreshWithSetup:(ChannelServiceSetup *)setup
{
    @weakify(self)
    SRGPaginatedProgramCompositionCompletionBlock completionBlock = ^(SRGProgramComposition * _Nullable programComposition, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        @strongify(self)
        
        if (programComposition) {
            self.programCompositions[setup] = programComposition;
        }
        
        NSMutableDictionary<NSString *, ChannelServiceUpdateBlock> *channelRegistrations = self.registrations[setup];
        for (ChannelServiceUpdateBlock updateBlock in channelRegistrations.allValues) {
            updateBlock(self.programCompositions[setup]);
        }
    };
    
    static const NSUInteger kPageSize = 50;
    
    SRGFirstPageRequest *request = nil;
    if (setup.channel.transmission == SRGTransmissionRadio) {
        request = [[SRGDataProvider.currentDataProvider radioLatestProgramsForVendor:setup.channel.vendor channelUid:setup.channel.uid livestreamUid:setup.livestreamUid fromDate:nil toDate:nil withCompletionBlock:completionBlock] requestWithPageSize:kPageSize];
    }
    else {
        request = [[SRGDataProvider.currentDataProvider tvLatestProgramsForVendor:setup.channel.vendor channelUid:setup.channel.uid livestreamUid:setup.livestreamUid fromDate:nil toDate:nil withCompletionBlock:completionBlock] requestWithPageSize:kPageSize];
    }
    [self.requestQueue addRequest:request resume:YES];
}

- (void)updateChannels
{
    self.requestQueue = [[SRGRequestQueue alloc] init];
    
    for (ChannelServiceSetup *setup in self.registrations) {
        [self refreshWithSetup:setup];
    }
}

#pragma mark Notifications

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if (ReachabilityBecameReachable(notification)) {
        [self updateChannels];
    }
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; registrations = %@>",
            self.class,
            self,
            self.registrations];
}

@end
