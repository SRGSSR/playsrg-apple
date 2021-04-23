//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Playlist.h"

#import "ApplicationConfiguration.h"
#import "History.h"
#import "Reachability.h"
#import "Recommendation.h"

// TODO: For the moment settings on tvOS are limited so ApplicationSettings has not been split / refactored
//       for simultaneous iOS / tvOS support. This could be improved when settings are enriched on tvOS.
#if TARGET_OS_TV
#import "ApplicationSettingsConstants.h"
#else
#import "ApplicationSettings.h"
#endif

@import libextobjc;
@import SRGDataProviderNetwork;

static Playlist *s_playlist;

@interface Playlist ()

@property (nonatomic, copy) NSString *URN;

@property (nonatomic) NSString *recommendationUid;

@property (nonatomic) NSArray<SRGMedia *> *medias;
@property (nonatomic) NSUInteger index;

@property (nonatomic) SRGRequestQueue *requestQueue;

@end

@implementation Playlist

#pragma mark Object lifecycle

- (instancetype)initWithURN:(NSString *)URN
{
    if (self = [super init]) {
        self.URN = URN;
        [self load];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(reachabilityDidChange:)
                                                   name:FXReachabilityStatusDidChangeNotification
                                                 object:nil];
    }
    return self;
}

#pragma mark Helpers

- (void)load
{
    if (self.medias) {
        return;
    }
    
    self.requestQueue = [[SRGRequestQueue alloc] init];
    
    NSString *resourcePath = [NSString stringWithFormat:@"api/v2/playlist/recommendation/continuousPlayback/%@", self.URN];
    NSURL *middlewareURL = ApplicationConfiguration.sharedApplicationConfiguration.middlewareURL;
    NSURL *URL = [NSURL URLWithString:resourcePath relativeToURL:middlewareURL];
    
    NSURLComponents *URLComponents = [NSURLComponents componentsWithString:URL.absoluteString];
    URLComponents.queryItems = @[ [NSURLQueryItem queryItemWithName:@"standalone" value:@"false"] ];
    
    SRGRequest *recommendationRequest = [[SRGRequest objectRequestWithURLRequest:[NSURLRequest requestWithURL:URLComponents.URL] session:NSURLSession.sharedSession parser:^id _Nullable(NSData * _Nonnull data, NSError * _Nullable __autoreleasing * _Nullable pError) {
        NSDictionary *JSONDictionary = SRGNetworkJSONDictionaryParser(data, pError);
        if (! JSONDictionary) {
            return nil;
        }
        
        return [MTLJSONAdapter modelOfClass:Recommendation.class fromJSONDictionary:JSONDictionary error:pError];
    } completionBlock:^(Recommendation * _Nullable recommendation, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || ! recommendation) {
            return;
        }
        
        SRGBaseRequest *mediasRequest = [[SRGDataProvider.currentDataProvider mediasWithURNs:recommendation.URNs completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            if (error) {
                return;
            }
            
            self.recommendationUid = recommendation.recommendationUid;
            
            NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGMedia * _Nullable media, NSDictionary<NSString *,id> * _Nullable bindings) {
                return HistoryCanResumePlaybackForMedia(media);
            }];
            self.medias = [medias filteredArrayUsingPredicate:predicate];
        }] requestWithPageSize:50];
        [self.requestQueue addRequest:mediasRequest resume:YES];
    }] requestWithOptions:SRGRequestOptionBackgroundCompletionEnabled];
    [self.requestQueue addRequest:recommendationRequest resume:YES];
}

#pragma SRGLetterboxControllerPlaylistDataSource protocol

- (SRGMedia *)previousMediaForController:(SRGLetterboxController *)controller
{
    if (self.medias.count == 0) {
        return nil;
    }
    else {
        return self.index > 0 ? self.medias[self.index - 1] : nil;
    }
}

- (SRGMedia *)nextMediaForController:(SRGLetterboxController *)controller
{
    if (self.medias.count == 0) {
        return nil;
    }
    else {
        return self.index < self.medias.count - 1 ? self.medias[self.index + 1] : nil;
    }
}

- (void)controller:(SRGLetterboxController *)controller didChangeToMedia:(SRGMedia *)media
{
    self.index = [self.medias indexOfObject:media];
}

- (SRGPosition *)controller:(SRGLetterboxController *)controller startPositionForMedia:(SRGMedia *)media
{
    return HistoryResumePlaybackPositionForMedia(media);
}

- (SRGLetterboxPlaybackSettings *)controller:(SRGLetterboxController *)controller preferredSettingsForMedia:(SRGMedia *)media
{
#if TARGET_OS_TV
    SRGLetterboxPlaybackSettings *playbackSettings = [[SRGLetterboxPlaybackSettings alloc] init];
#else
    SRGLetterboxPlaybackSettings *playbackSettings = ApplicationSettingPlaybackSettings();
#endif
    playbackSettings.sourceUid = self.recommendationUid;
    return playbackSettings;
}

#pragma SRGLetterboxControllerPlaybackTransitionDelegate protocol

- (NSTimeInterval)continuousPlaybackTransitionDurationForController:(SRGLetterboxController *)controller
{
#if TARGET_OS_TV
    if ([NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingAutoplayEnabled]) {
        return ApplicationConfiguration.sharedApplicationConfiguration.continuousPlaybackPlayerViewTransitionDuration;
    }
    else {
        return SRGLetterboxContinuousPlaybackDisabled;
    }
#else
    return ApplicationSettingContinuousPlaybackTransitionDuration();
#endif
}

#if TARGET_OS_TV
- (void)controllerDidEndPlaybackdWithoutTransition:(SRGLetterboxController *)controller
{
    UIViewController *topViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    if ([topViewController isKindOfClass:SRGLetterboxViewController.class]) {
        [topViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
#endif

#pragma mark Notifications

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if (ReachabilityBecameReachable(notification)) {
        [self load];
    }
}

@end

Playlist *PlaylistForURN(NSString *URN)
{
    s_playlist = URN ? [[Playlist alloc] initWithURN:URN] : nil;
    return s_playlist;
}
