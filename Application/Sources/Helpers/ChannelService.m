//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ChannelService.h"

#import "ChannelServiceSetup.h"
#import "ForegroundTimer.h"
#import "SRGProgram+PlaySRG.h"

#import <CoconutKit/CoconutKit.h>
#import <FXReachability/FXReachability.h>
#import <libextobjc/libextobjc.h>

@interface ChannelService ()

@property (nonatomic) NSMutableDictionary<ChannelServiceSetup *, NSMutableDictionary<NSString *, ChannelProgramsUpdateBlock> *> *programRegistrations;
@property (nonatomic) NSMutableDictionary<ChannelServiceSetup *, NSMutableDictionary<NSString *, ChannelSongsUpdateBlock> *> *songRegistrations;

// Cache channels. This cache is never invalidated, but its data is likely rarely to be staled as it is regularly updated. Cached
// data is used to return existing channel information as fast as possible, and when errors have been encountered.
@property (nonatomic) NSMutableDictionary<ChannelServiceSetup *, SRGProgramComposition *> *programCompositionMap;
@property (nonatomic) NSMutableDictionary<ChannelServiceSetup *, NSArray<SRGSong *> *> *songsMap;

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
        self.programRegistrations = [NSMutableDictionary dictionary];
        self.songRegistrations = [NSMutableDictionary dictionary];
        
        self.programCompositionMap = [NSMutableDictionary dictionary];
        self.songsMap = [NSMutableDictionary dictionary];
        
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

- (id)addObserver:(id)observer forProgramUpdatesWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor livestreamUid:(NSString *)livestreamUid block:(ChannelProgramsUpdateBlock)block
{
    if (channel.transmission != SRGTransmissionTV && channel.transmission != SRGTransmissionRadio) {
        return nil;
    }
    
    ChannelServiceSetup *setup = [[ChannelServiceSetup alloc] initWithChannel:channel vendor:vendor livestreamUid:livestreamUid];
    NSMutableDictionary<NSString *, ChannelProgramsUpdateBlock> *channelRegistrations = self.programRegistrations[setup];
    if (! channelRegistrations) {
        channelRegistrations = [NSMutableDictionary dictionary];
        self.programRegistrations[setup] = channelRegistrations;
    }
    
    NSString *identifier = NSUUID.UUID.UUIDString;
    channelRegistrations[identifier] = block;
    
    // Return data immediately available from the cache, but still trigger an update
    SRGProgramComposition *programComposition = self.programCompositionMap[setup];
    if (programComposition) {
        block(programComposition);
    }
    
    // Only force an update the first time a channel is added. Other updates will occur perodically afterwards.
    if (channelRegistrations.count == 1) {
        [self refreshProgramWithSetup:setup];
    }
    
    return identifier;
}

- (id)addObserver:(id)observer forSongUpdatesWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor block:(ChannelSongsUpdateBlock)block
{
    if (channel.transmission != SRGTransmissionRadio) {
        return nil;
    }
    
    ChannelServiceSetup *setup = [[ChannelServiceSetup alloc] initWithChannel:channel vendor:vendor livestreamUid:nil];
    NSMutableDictionary<NSString *, ChannelSongsUpdateBlock> *channelRegistrations = self.songRegistrations[setup];
    if (! channelRegistrations) {
        channelRegistrations = [NSMutableDictionary dictionary];
        self.songRegistrations[setup] = channelRegistrations;
    }
    
    NSString *identifier = NSUUID.UUID.UUIDString;
    channelRegistrations[identifier] = block;
    
    // Return data immediately available from the cache, but still trigger an update
    NSArray<SRGSong *> *songs = self.songsMap[setup];
    if (songs) {
        block(songs);
    }
    
    // Only force an update the first time a channel is added. Other updates will occur perodically afterwards.
    if (channelRegistrations.count == 1) {
        [self refreshSongsWithSetup:setup];
    }
    
    return identifier;
}

- (void)removeObserver:(id)observer
{
    if (! observer) {
        return;
    }
    
    for (NSMutableDictionary<NSString *, ChannelProgramsUpdateBlock> *channelRegistrations in self.programRegistrations.allValues) {
        [channelRegistrations removeObjectForKey:observer];
    }
    
    // Keep registered channels for the lifetime of the app, do not remove associated entries (otherwise we might
    // remove and add channels repeatedly, triggering an update each time)
}

#pragma mark Data retrieval

- (void)refreshProgramWithSetup:(ChannelServiceSetup *)setup
{
    @weakify(self)
    SRGPaginatedProgramCompositionCompletionBlock completionBlock = ^(SRGProgramComposition * _Nullable programComposition, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        @strongify(self)
        
        if (programComposition) {
            self.programCompositionMap[setup] = programComposition;
        }
        
        NSMutableDictionary<NSString *, ChannelProgramsUpdateBlock> *channelRegistrations = self.programRegistrations[setup];
        for (ChannelProgramsUpdateBlock updateBlock in channelRegistrations.allValues) {
            updateBlock(self.programCompositionMap[setup]);
        }
    };
    
    static const NSUInteger kPageSize = 50;
    
    SRGFirstPageRequest *request = nil;
    if (setup.channel.transmission == SRGTransmissionRadio) {
        // Regional livestreams. Currently only for SRF
        if (setup.vendor == SRGVendorSRF && ! [setup.livestreamUid isEqualToString:setup.channel.uid]) {
            request = [[SRGDataProvider.currentDataProvider radioLatestProgramsForVendor:setup.vendor channelUid:setup.channel.uid livestreamUid:setup.livestreamUid fromDate:nil toDate:nil withCompletionBlock:completionBlock] requestWithPageSize:kPageSize];
        }
        else {
            request = [[SRGDataProvider.currentDataProvider radioLatestProgramsForVendor:setup.vendor channelUid:setup.channel.uid livestreamUid:nil fromDate:nil toDate:nil withCompletionBlock:completionBlock] requestWithPageSize:kPageSize];
        }
    }
    else {
        request = [[SRGDataProvider.currentDataProvider tvLatestProgramsForVendor:setup.vendor channelUid:setup.channel.uid fromDate:nil toDate:nil withCompletionBlock:completionBlock] requestWithPageSize:kPageSize];
    }
    [self.requestQueue addRequest:request resume:YES];
}

- (void)refreshSongsWithSetup:(ChannelServiceSetup *)setup
{
    static const NSUInteger kPageSize = 50;
    
    @weakify(self)
    SRGFirstPageRequest *request = [[SRGDataProvider.currentDataProvider radioSongsForVendor:setup.vendor channelUid:setup.channel.uid withCompletionBlock:^(NSArray<SRGSong *> * _Nullable songs, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        @strongify(self)
        
        if (songs) {
            self.songsMap[setup] = songs;
        }
        
        NSMutableDictionary<NSString *, ChannelSongsUpdateBlock> *channelRegistrations = self.songRegistrations[setup];
        for (ChannelSongsUpdateBlock updateBlock in channelRegistrations.allValues) {
            updateBlock(self.songsMap[setup]);
        }
    }] requestWithPageSize:kPageSize];
    [self.requestQueue addRequest:request resume:YES];
}

- (void)updateChannels
{
    self.requestQueue = [[SRGRequestQueue alloc] init];
    
    for (ChannelServiceSetup *setup in self.programRegistrations) {
        [self refreshProgramWithSetup:setup];
    }
    for (ChannelServiceSetup *setup in self.songRegistrations) {
        [self refreshSongsWithSetup:setup];
    }
}

#pragma mark Notifications

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if ([FXReachability sharedInstance].reachable) {
        [self updateChannels];
    }
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; programRegistrations = %@; songRegistrations = %@>",
            self.class,
            self,
            self.programRegistrations,
            self.songRegistrations];
}

@end
