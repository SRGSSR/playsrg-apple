//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "GoogleCast.h"

#import "ApplicationConfiguration.h"
#import "History.h"
#import "PlayErrors.h"
#import "UIViewController+PlaySRG.h"
#import "UIWindow+PlaySRG.h"

#import <objc/runtime.h>

@import GoogleCast;
@import SRGAnalytics;

NSString * const GoogleCastPlaybackDidStartNotification = @"GoogleCastPlaybackDidStartNotification";
NSString * const GoogleCastMediaKey = @"GoogleCastMedia";

@interface GoogleCastManager : NSObject

@end

static GoogleCastManager *s_googleCastManager;

void GoogleCastSetup(void)
{
    s_googleCastManager = [[GoogleCastManager alloc] init];
}

BOOL GoogleCastIsPossible(SRGMediaComposition *mediaComposition, NSError **pError)
{
    GCKDevice *castDevice = [GCKCastContext sharedInstance].sessionManager.currentCastSession.device;
    if (! castDevice) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeReceiver
                                      userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"No Google Cast receiver is available.", @"Message displayed if no Google Cast receiver is available") }];
        }
        return NO;
    }
    
    SRGChapter *mainChapter = mediaComposition.mainChapter;
    SRGBlockingReason blockingReason = [mainChapter blockingReasonAtDate:NSDate.date];
    
    // Check device compatibility
    if (mainChapter.mediaType == SRGMediaTypeVideo && ! [castDevice hasCapabilities:GCKDeviceCapabilityVideoOut]) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeReceiver
                                      userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The Google Cast receiver cannot play videos.", @"Message displayed if the Google Cast receiver cannot play videos") }];
        }
        return NO;
    }
    else if (mainChapter.mediaType == SRGMediaTypeAudio && ! [castDevice hasCapabilities:GCKDeviceCapabilityAudioOut]) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeReceiver
                                      userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The Google Cast receiver cannot play audios.", @"Message displayed if the Google Cast receiver cannot play audios") }];
        }
        return NO;
    }
    else if (blockingReason != SRGBlockingReasonNone) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeForbidden
                                      userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"This content is not allowed to be played with Google Cast.", @"Message displayed when attempting to play some content not allowed to be played with Google Cast") }];
        }
        return NO;
    }
    
    // Do not let the content be played if it contains a blocked segment
    NSPredicate *blockedSegmentsPredicate = [NSPredicate predicateWithBlock:^BOOL(SRGSegment * _Nullable segment, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [segment blockingReasonAtDate:NSDate.date] != SRGBlockingReasonNone;
    }];
    NSArray<SRGSegment *> *blockedSegments = [mainChapter.segments filteredArrayUsingPredicate:blockedSegmentsPredicate];
    if (blockedSegments.count != 0) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeForbidden
                                      userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"This content is not allowed to be played with Google Cast.", @"Message displayed when attempting to play some content not allowed to be played with Google Cast") }];
        }
        return NO;
    }
    
    // Do not let the content be played if it is a full-length and a chapter related to it is blocked
    NSPredicate *blockedAffiliatedChaptersPredicate = [NSPredicate predicateWithBlock:^BOOL(SRGChapter * _Nullable chapter, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [chapter.fullLengthURN isEqual:mainChapter.URN] && [chapter blockingReasonAtDate:NSDate.date] != SRGBlockingReasonNone;
    }];
    NSArray<SRGChapter *> *blockedAffiliatedChapters = [mediaComposition.chapters filteredArrayUsingPredicate:blockedAffiliatedChaptersPredicate];
    if (blockedAffiliatedChapters.count != 0) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeForbidden
                                      userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"This content is not allowed to be played with Google Cast.", @"Message displayed when attempting to play some content not allowed to be played with Google Cast") }];
        }
        return NO;
    }
    
    return YES;
}

BOOL GoogleCastPlayMediaComposition(SRGMediaComposition *mediaComposition, SRGPosition *position, NSError **pError)
{
    if (! GoogleCastIsPossible(mediaComposition, pError)) {
        return NO;
    }
    
    SRGChapter *mainChapter = mediaComposition.mainChapter;
    
    GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];
    [metadata setString:mainChapter.title forKey:kGCKMetadataKeyTitle];
    
    NSString *subtitle = mainChapter.lead;
    if (subtitle) {
        [metadata setString:subtitle forKey:kGCKMetadataKeySubtitle];
    }
    
    GCKMediaInformationBuilder *mediaInfoBuilder = [[GCKMediaInformationBuilder alloc] init];
    mediaInfoBuilder.contentID = mediaComposition.chapterURN;
    mediaInfoBuilder.streamType = GCKMediaStreamTypeNone;
    mediaInfoBuilder.metadata = metadata;
    mediaInfoBuilder.customData = @{ @"server" : SRGDataProvider.currentDataProvider.serviceURL.host };
    
    GCKCastSession *castSession = [GCKCastContext sharedInstance].sessionManager.currentCastSession;
    GCKMediaLoadOptions *options = [[GCKMediaLoadOptions alloc] init];
    
    // Only apply playing position for on-demand streams. Does not work well with other kinds of streams.
    CMTime time = [position.mark timeForMediaPlayerController:nil];
    BOOL isLivestream = mainChapter.contentType == SRGContentTypeLivestream || mainChapter.contentType == SRGContentTypeScheduledLivestream;
    if (! isLivestream && CMTIME_IS_VALID(time) && CMTIME_COMPARE_INLINE(time, !=, kCMTimeZero)) {
        float progress = HistoryPlaybackProgress(CMTimeGetSeconds(time), mainChapter.duration / 1000.);
        if (progress != 1.f) {
            options.playPosition = CMTimeGetSeconds(time);
        }
    }
    [castSession.remoteMediaClient loadMedia:[mediaInfoBuilder build] withOptions:options];
    
    SRGMedia *media = [mediaComposition mediaForSubdivision:mainChapter];
    [NSNotificationCenter.defaultCenter postNotificationName:GoogleCastPlaybackDidStartNotification
                                                      object:nil
                                                    userInfo:@{ GoogleCastMediaKey : media }];
    
    return YES;
}

@implementation GoogleCastManager

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
        
        GCKDiscoveryCriteria *discoveryCriteria = [[GCKDiscoveryCriteria alloc] initWithApplicationID:applicationConfiguration.googleCastReceiverIdentifier];
        GCKCastOptions *options = [[GCKCastOptions alloc] initWithDiscoveryCriteria:discoveryCriteria];
        [GCKCastContext setSharedInstanceWithOptions:options];
        [GCKCastContext sharedInstance].useDefaultExpandedMediaControls = YES;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(googleCastStateDidChange:)
                                                   name:kGCKCastStateDidChangeNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationDidBecomeActive:)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
        
        // If the GoogleCastManager is created from the app delegate (which is the best way to ensure Google Cast is setup
        // early, so that accessing other related UI components works as expected), we can still apply styling slightly
        // afterwards, so that the associated performance impact is mitigated.
        dispatch_async(dispatch_get_main_queue(), ^{
            GCKUIStyleAttributes *styleAttributes = [GCKUIStyle sharedInstance].castViews;
            styleAttributes.closedCaptionsImage = [UIImage imageNamed:@"subtitles_off-22"];
            styleAttributes.forward30SecondsImage = [UIImage imageNamed:@"forward-50"];
            styleAttributes.rewind30SecondsImage = [UIImage imageNamed:@"backward-50"];
            styleAttributes.muteOffImage = [UIImage imageNamed:@"player_mute-22"];
            styleAttributes.muteOnImage = [UIImage imageNamed:@"player_unmute-22"];
            styleAttributes.pauseImage = [UIImage imageNamed:@"pause-50"];
            styleAttributes.playImage = [UIImage imageNamed:@"play-50"];
            styleAttributes.stopImage = [UIImage imageNamed:@"pause-50"];
            // The subtitlesTrackImage property is buggy (the original icon is displayed when highlighted)
        });
    }
    return self;
}

#pragma mark Notifications

- (void)googleCastStateDidChange:(NSNotification *)notification
{
    GCKCastState castState = [notification.userInfo[kGCKNotificationKeyCastState] integerValue];
    if (castState == GCKCastStateConnected) {
        SRGLetterboxService *service = SRGLetterboxService.sharedService;
        SRGLetterboxController *controller = service.controller;
        
        // Transfer local playback to Google Cast
        if (controller.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
            [UIApplication.sharedApplication.keyWindow.play_topViewController play_presentMediaPlayerFromLetterboxController:controller withAirPlaySuggestions:NO fromPushNotification:NO animated:YES completion:^(PlayerType playerType) {
                if (playerType == PlayerTypeGoogleCast) {
                    [service disable];
                    [controller reset];
                }
            }];
        }
    }
}

// Perform manual tracking of Google cast views when the application returns from background
- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.play_topViewController;
    if ([topViewController isKindOfClass:GCKUIExpandedMediaControlsViewController.class]) {
        [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:AnalyticsPageTitlePlayer levels:@[ AnalyticsPageLevelPlay, AnalyticsPageLevelGoogleCast ]];
    }
    else if ([topViewController isKindOfClass:UINavigationController.class]) {
        UINavigationController *navigationTopViewController = (UINavigationController *)topViewController;
        UIViewController *rootViewController = navigationTopViewController.viewControllers.firstObject;
        if ([rootViewController isKindOfClass:NSClassFromString(@"GCKUIDeviceConnectionViewController")]) {
            [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:AnalyticsPageTitleDevices levels:@[ AnalyticsPageLevelPlay, AnalyticsPageLevelGoogleCast ]];
        }
    }
}

@end

@interface GCKUICastButton (GoogleCast)

- (void)openGoogleCastDeviceSelection:(id)sender;

@end

static void commonInit(GCKUICastButton *self)
{
    [self addTarget:self action:@selector(openGoogleCastDeviceSelection:) forControlEvents:UIControlEventTouchUpInside];
}

@implementation GCKUICastButton (GoogleCast)

#pragma mark Class methods

+ (void)load
{
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(initWithFrame:)),
                                   class_getInstanceMethod(self, @selector(GCKUICastButton_GoogleCast_swizzled_initWithFrame:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(initWithCoder:)),
                                   class_getInstanceMethod(self, @selector(GCKUICastButton_GoogleCast_swizzled_initWithCoder:)));
}

#pragma mark Swizzled methods

- (id)GCKUICastButton_GoogleCast_swizzled_initWithFrame:(CGRect)frame
{
    id zelf = [self GCKUICastButton_GoogleCast_swizzled_initWithFrame:frame];
    if (zelf) {
        commonInit(zelf);
    }
    return zelf;
}

- (id)GCKUICastButton_GoogleCast_swizzled_initWithCoder:(NSCoder *)decoder
{
    id zelf = [self GCKUICastButton_GoogleCast_swizzled_initWithCoder:decoder];
    if (zelf) {
        commonInit(zelf);
    }
    return zelf;
}

#pragma mark Actions

- (void)openGoogleCastDeviceSelection:(id)sender
{
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:AnalyticsPageTitleDevices levels:@[ AnalyticsPageLevelPlay, AnalyticsPageLevelGoogleCast ]];
}

@end
