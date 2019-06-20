//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+PlaySRG.h"

#import "AnalyticsConstants.h"
#import "ApplicationSettings.h"
#import "Banner.h"
#import "GoogleCast.h"
#import "History.h"
#import "MediaPlayerViewController.h"
#import "PlayErrors.h"
#import "Playlist.h"
#import "Previewing.h"
#import "PreviewingDelegate.h"
#import "UIDevice+PlaySRG.h"
#import "UIWindow+PlaySRG.h"

#import <CoconutKit/CoconutKit.h>
#import <GoogleCast/GoogleCast.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>

static Playlist *s_playlist;

static Playlist *SharedPlaylistForURN(NSString *URN)
{
    s_playlist = URN ? [[Playlist alloc] initWithURN:URN] : nil;
    return s_playlist;
}

// We retain the presentation delegates with the view controller. If not unregistered, UIKit cleans them up when the
// view controller is deallocated anyway. We must retain the delegates, otherwise they will get deallocated early
static void *s_previewingDelegatesKey = &s_previewingDelegatesKey;
static void *s_longPressGestureRecognizerKey = &s_longPressGestureRecognizerKey;
static void *s_previewingContextKey = &s_previewingContextKey;

// Original implementation of the methods we swizzle
static id (*s_registerForPreviewingWithDelegate_sourceView)(id, SEL, id, id) = NULL;
static void (*s_unregisterForPreviewingWithContext)(id, SEL, id) = NULL;

// Swizzled method implementations
static id<UIViewControllerPreviewing> swizzle_registerForPreviewingWithDelegate_sourceView(UIViewController *self, SEL _cmd, id<UIViewControllerPreviewingDelegate> delegate, UIView *sourceView);
static void swizzle_unregisterForPreviewingWithContext(UIViewController *self, SEL _cmd, id<UIViewControllerPreviewing> context);

@implementation UIViewController (PlaySRG)

#pragma mark Class methods

+ (void)load
{
    HLSSwizzleSelector(self, @selector(registerForPreviewingWithDelegate:sourceView:), swizzle_registerForPreviewingWithDelegate_sourceView, &s_registerForPreviewingWithDelegate_sourceView);
    HLSSwizzleSelector(self, @selector(unregisterForPreviewingWithContext:), swizzle_unregisterForPreviewingWithContext, &s_unregisterForPreviewingWithContext);
}

+ (UIInterfaceOrientationMask)play_supportedInterfaceOrientations
{
    switch (UIDevice.play_deviceType) {
        case DeviceTypePhonePlus: {
            return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
            break;
        }
            
        case DeviceTypePhoneOther: {
            return UIInterfaceOrientationMaskPortrait;
            break;
        }
            
        case DeviceTypePad: {
            return UIInterfaceOrientationMaskAll;
            break;
        }
            
        default: {
            return UIInterfaceOrientationMaskPortrait;
            break;
        }
    }
}

#pragma mark Getters and setters

- (BOOL)play_isMovingToParentViewController
{
    if (self.movingToParentViewController || self.beingPresented) {
        return YES;
    }
    
    // Page view controllers are buggy and do not consider the child to be moving to the controller when appearing. The check is not
    // valid outside view controller's view lifecycle methods
    if ([self.parentViewController isKindOfClass:UIPageViewController.class]) {
        return YES;
    }
    
    UIViewController *parentViewController = self.parentViewController;
    while (parentViewController) {
        if ([parentViewController play_isMovingFromParentViewController]) {
            return YES;
        }
        parentViewController = parentViewController.parentViewController;
    }
    
    return NO;
}

- (BOOL)play_isMovingFromParentViewController
{
    if (self.movingFromParentViewController || self.beingDismissed) {
        return YES;
    }
    
    // See comment above. The parent view controller for a page view controller is still the controller, even in -viewDidDisappear:
    if ([self.parentViewController isKindOfClass:UIPageViewController.class]) {
        return YES;
    }
    
    UIViewController *parentViewController = self.parentViewController;
    while (parentViewController) {
        if ([parentViewController play_isMovingFromParentViewController]) {
            return YES;
        }
        parentViewController = parentViewController.parentViewController;
    }
    
    return NO;
}

#pragma mark Gesture recognizers

- (void)play_showPreviewForSourceView:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [UIApplication.sharedApplication sendAction:@selector(showPreviewForSourceView:) to:self from:gestureRecognizer.view forEvent:nil];
    }
}

#pragma mark Home indicator management

- (void)play_setNeedsUpdateOfHomeIndicatorAutoHidden
{
    if (@available(iOS 11, *)) {
        if ([self respondsToSelector:@selector(setNeedsUpdateOfHomeIndicatorAutoHidden)]) {
            [self setNeedsUpdateOfHomeIndicatorAutoHidden];
        }
    }
}

#pragma mark Previewing

- (void)setPlay_previewingContext:(id<UIViewControllerPreviewing>)previewingContext
{
    objc_setAssociatedObject(self, s_previewingContextKey, previewingContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<UIViewControllerPreviewing>)play_previewingContext
{
    return objc_getAssociatedObject(self, s_previewingContextKey);
}

#pragma mark Media player presentation

- (void)play_presentMediaPlayerWithMedia:(SRGMedia *)media position:(SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (! position) {
        position = HistoryResumePlaybackPositionForMedia(media);
    }
    GCKCastSession *castSession = [GCKCastContext sharedInstance].sessionManager.currentCastSession;
    if (castSession) {
        [self play_presentGoogleCastPlayerWithMedia:media standalone:YES atPosition:position fromPushNotification:fromPushNotification animated:animated completion:completion];
    }
    else {
        [self play_presentNativeMediaPlayerWithMedia:media atPosition:position fromPushNotification:fromPushNotification animated:animated responder:self completion:completion];
    }
}

- (void)play_presentMediaPlayerFromLetterboxController:(SRGLetterboxController *)letterboxController fromPushNotification:(BOOL)fromPushNotification animated:(BOOL)animated completion:(void (^)(void))completion
{
    GCKCastSession *castSession = [GCKCastContext sharedInstance].sessionManager.currentCastSession;
    if (castSession) {
        [self play_presentGoogleCastPlayerFromLetterboxController:letterboxController fromPushNotification:fromPushNotification animated:animated completion:completion];
    }
    else {
        [self play_presentNativeMediaPlayerFromLetterboxController:letterboxController fromPushNotification:fromPushNotification animated:animated responder:self completion:completion];
    }
}

#pragma mark Implementation helpers

- (void)play_presentMediaPlayerWithMedia:(SRGMedia *)media atPosition:(SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification animated:(BOOL)animated responder:(UIResponder *)responder completion:(void (^)(void))completion
{
    GCKCastSession *castSession = [GCKCastContext sharedInstance].sessionManager.currentCastSession;
    if (castSession) {
        [self play_presentGoogleCastPlayerWithMedia:media standalone:YES atPosition:position fromPushNotification:fromPushNotification animated:animated completion:completion];
    }
    else {
        [self play_presentNativeMediaPlayerWithMedia:media atPosition:position fromPushNotification:fromPushNotification animated:animated responder:responder completion:completion];
    }
}

- (void)play_presentMediaPlayerFromLetterboxController:(SRGLetterboxController *)letterboxController fromPushNotification:(BOOL)fromPushNotification animated:(BOOL)animated responder:(UIResponder *)responder completion:(void (^)(void))completion
{
    GCKCastSession *castSession = [GCKCastContext sharedInstance].sessionManager.currentCastSession;
    if (castSession) {
        [self play_presentGoogleCastPlayerFromLetterboxController:letterboxController fromPushNotification:fromPushNotification animated:animated completion:completion];
    }
    else {
        [self play_presentNativeMediaPlayerFromLetterboxController:letterboxController fromPushNotification:fromPushNotification animated:animated responder:responder completion:completion];
    }
}

- (void)play_presentNativeMediaPlayerWithURN:(NSString *)URN atPosition:(SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification animated:(BOOL)animated responder:(UIResponder *)responder completion:(void (^)(void))completion
{
    UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.play_topViewController;
    if ([topViewController isKindOfClass:MediaPlayerViewController.class]) {
        MediaPlayerViewController *mediaPlayerViewController = (MediaPlayerViewController *)topViewController;
        SRGLetterboxController *letterboxController = mediaPlayerViewController.letterboxController;
        letterboxController.playlistDataSource = SharedPlaylistForURN(URN);
        
        if ([letterboxController.URN isEqual:URN] && letterboxController.playbackState != SRGMediaPlayerPlaybackStateIdle
                && letterboxController.playbackState != SRGMediaPlayerPlaybackStatePreparing
                && letterboxController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
            [letterboxController seekToPosition:position withCompletionHandler:^(BOOL finished) {
                [letterboxController play];
            }];
        }
        else {
            [letterboxController playURN:URN atPosition:position withPreferredSettings:ApplicationSettingPlaybackSettings()];
        }
        completion ? completion() : nil;
    }
    else {
        MediaPlayerViewController *mediaPlayerViewController = [[MediaPlayerViewController alloc] initWithURN:URN position:position fromPushNotification:fromPushNotification];
        SRGLetterboxController *letterboxController = mediaPlayerViewController.letterboxController;
        letterboxController.playlistDataSource = SharedPlaylistForURN(URN);
        [topViewController presentViewController:mediaPlayerViewController animated:animated completion:completion];
    }
}

- (void)play_presentNativeMediaPlayerWithMedia:(SRGMedia *)media atPosition:(SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification animated:(BOOL)animated responder:(UIResponder *)responder completion:(void (^)(void))completion
{
    UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.play_topViewController;
    if ([topViewController isKindOfClass:MediaPlayerViewController.class]) {
        MediaPlayerViewController *mediaPlayerViewController = (MediaPlayerViewController *)topViewController;
        SRGLetterboxController *letterboxController = mediaPlayerViewController.letterboxController;
        letterboxController.playlistDataSource = SharedPlaylistForURN(media.URN);
        
        if ([letterboxController.media isEqual:media] && letterboxController.playbackState != SRGMediaPlayerPlaybackStateIdle
                && letterboxController.playbackState != SRGMediaPlayerPlaybackStatePreparing
                && letterboxController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
            [letterboxController seekToPosition:position withCompletionHandler:^(BOOL finished) {
                [letterboxController play];
            }];
        }
        else {
            [letterboxController playMedia:media atPosition:position withPreferredSettings:ApplicationSettingPlaybackSettings()];
        }
        completion ? completion() : nil;
    }
    else {
        MediaPlayerViewController *mediaPlayerViewController = [[MediaPlayerViewController alloc] initWithMedia:media position:position fromPushNotification:fromPushNotification];
        SRGLetterboxController *letterboxController = mediaPlayerViewController.letterboxController;
        letterboxController.playlistDataSource = SharedPlaylistForURN(media.URN);
        [topViewController presentViewController:mediaPlayerViewController animated:animated completion:completion];
    }
}

- (void)play_presentNativeMediaPlayerFromLetterboxController:(SRGLetterboxController *)letterboxController fromPushNotification:(BOOL)fromPushNotification animated:(BOOL)animated responder:(UIResponder *)responder completion:(void (^)(void))completion
{
    UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.play_topViewController;
    if ([topViewController isKindOfClass:MediaPlayerViewController.class]) {
        MediaPlayerViewController *mediaPlayerViewController = (MediaPlayerViewController *)topViewController;
        if (mediaPlayerViewController.letterboxController == letterboxController) {
            completion ? completion() : nil;
            return;
        }
    }
    
    MediaPlayerViewController *mediaPlayerViewController = [[MediaPlayerViewController alloc] initWithController:letterboxController position:nil fromPushNotification:fromPushNotification];
    letterboxController.playlistDataSource = SharedPlaylistForURN(letterboxController.URN);
    [topViewController presentViewController:mediaPlayerViewController animated:animated completion:completion];
}

// The completion block returns cast errors only. To know whether playback could correctly start, check the started boolean
- (void)play_prepareGoogleCastPlaybackWithMediaComposition:(SRGMediaComposition *)mediaComposition position:(SRGPosition *)position completion:(void (^)(BOOL started, NSError * _Nullable error))completion
{
    if (! mediaComposition) {
        completion ? completion(NO, nil) : nil;
        return;
    }
    
    NSError *castError = nil;
    if (! GoogleCastIsPossible(mediaComposition, &castError)) {
        completion ? completion(NO, castError) : nil;
        return;
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
    CMTime time = position.time;
    BOOL isLivestream = mainChapter.contentType == SRGContentTypeLivestream || mainChapter.contentType == SRGContentTypeScheduledLivestream;
    if (! isLivestream && CMTIME_IS_VALID(time) && CMTIME_COMPARE_INLINE(time, !=, kCMTimeZero)) {
        float progress = HistoryPlaybackProgress(CMTimeGetSeconds(time), mainChapter.duration / 1000.);
        if (progress != 1.f) {
            options.playPosition = CMTimeGetSeconds(time);
        }
    }
    [castSession.remoteMediaClient loadMedia:[mediaInfoBuilder build] withOptions:options];
    
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.value = mainChapter.URN;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleGoogleCast labels:labels];
    
    completion ? completion(YES, nil) : nil;
}

- (void)play_presentGoogleCastControlsAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.play_topViewController;
    if (! [topViewController isKindOfClass:GCKUIExpandedMediaControlsViewController.class]) {
        GCKUIExpandedMediaControlsViewController *mediaControlsViewController = [GCKCastContext sharedInstance].defaultExpandedMediaControlsViewController;
        mediaControlsViewController.hideStreamPositionControlsForLiveContent = YES;
        [self presentViewController:mediaControlsViewController animated:animated completion:completion];
    }
}

- (void)play_presentGoogleCastPlayerWithURN:(NSString *)URN standalone:(BOOL)standalone atPosition:(SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification animated:(BOOL)animated completion:(void (^)(void))completion
{
    [[SRGDataProvider.currentDataProvider mediaCompositionForURN:URN standalone:standalone withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        void (^presentNativePlayer)(NSString *) = ^(NSString *message) {
            [self play_presentNativeMediaPlayerWithURN:URN atPosition:position fromPushNotification:fromPushNotification animated:animated responder:self completion:^{
                [Banner showWithStyle:BannerStyleInfo message:message image:nil sticky:NO inViewController:nil /* self is being covered */];
                completion ? completion() : nil;
            }];
        };
        
        if (error) {
            presentNativePlayer(nil);
            return;
        }
        
        [self play_prepareGoogleCastPlaybackWithMediaComposition:mediaComposition position:position completion:^(BOOL started, NSError * _Nullable error) {
            if (started) {
                [self play_presentGoogleCastControlsAnimated:animated completion:completion];
            }
            else {
                presentNativePlayer(error.localizedDescription);
            }
        }];
    }] resume];
}

- (void)play_presentGoogleCastPlayerWithMedia:(SRGMedia *)media standalone:(BOOL)standalone atPosition:(SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification animated:(BOOL)animated completion:(void (^)(void))completion
{
    [[SRGDataProvider.currentDataProvider mediaCompositionForURN:media.URN standalone:standalone withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        void (^presentNativePlayer)(NSString *) = ^(NSString *message) {
            [self play_presentNativeMediaPlayerWithMedia:media atPosition:position fromPushNotification:fromPushNotification animated:animated responder:self completion:^{
                [Banner showWithStyle:BannerStyleInfo message:message image:nil sticky:NO inViewController:nil /* self is being covered */];
                completion ? completion() : nil;
            }];
        };
        
        if (error) {
            presentNativePlayer(nil);
            return;
        }
        
        [self play_prepareGoogleCastPlaybackWithMediaComposition:mediaComposition position:position completion:^(BOOL started, NSError * _Nullable error) {
            if (started) {
                [self play_presentGoogleCastControlsAnimated:animated completion:completion];
            }
            else {
                presentNativePlayer(error.localizedDescription);
            }
        }];
    }] resume];
}

- (void)play_presentGoogleCastPlayerFromLetterboxController:(SRGLetterboxController *)letterboxController fromPushNotification:(BOOL)fromPushNotification animated:(BOOL)animated completion:(void (^)(void))completion
{
    SRGPosition *position = [SRGPosition positionAtTime:letterboxController.currentTime];
    [self play_prepareGoogleCastPlaybackWithMediaComposition:letterboxController.mediaComposition position:position completion:^(BOOL started, NSError * _Nullable error) {
        if (started) {
            [self play_presentGoogleCastControlsAnimated:animated completion:completion];
        }
        else {
            [self play_presentNativeMediaPlayerFromLetterboxController:letterboxController fromPushNotification:fromPushNotification animated:animated responder:self completion:^{
                [Banner showWithStyle:BannerStyleInfo message:error.localizedDescription image:nil sticky:NO inViewController:nil /* self is being covered */];
                completion ? completion() : nil;
            }];
        }
    }];
}

@end

#pragma mark Functions

static id<UIViewControllerPreviewing> swizzle_registerForPreviewingWithDelegate_sourceView(UIViewController *self, SEL _cmd, id<UIViewControllerPreviewingDelegate> delegate, UIView *sourceView)
{
    NSMutableSet<PreviewingDelegate *> *previewingDelegates = objc_getAssociatedObject(self, s_previewingDelegatesKey);
    if (! previewingDelegates) {
        previewingDelegates = [NSMutableSet set];
        objc_setAssociatedObject(self, s_previewingDelegatesKey, previewingDelegates, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    PreviewingDelegate *previewingDelegate = [[PreviewingDelegate alloc] initWithRealDelegate:delegate];
    [previewingDelegates addObject:previewingDelegate];
    
    id<UIViewControllerPreviewing> previewingViewController = nil;
    
    // 3D Touch support available, use it
    // Warning: FLEX lies about 3D touch support. When running the app in the simulator with FLEX linked, the following
    //          condition is always true
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
        previewingViewController = s_registerForPreviewingWithDelegate_sourceView(self, _cmd, previewingDelegate, sourceView);
    }
    // No 3D Touch support available. Register for a long press if the view controller wants to support it
    if ([self conformsToProtocol:@protocol(LegacyPreviewingSupport)]) {
        UIGestureRecognizer *longPressGestureRecognizer = hls_getAssociatedObject(sourceView, s_longPressGestureRecognizerKey);
        if (longPressGestureRecognizer) {
            [sourceView removeGestureRecognizer:longPressGestureRecognizer];
        }
        
        longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(play_showPreviewForSourceView:)];
        [sourceView addGestureRecognizer:longPressGestureRecognizer];
        hls_setAssociatedObject(sourceView, s_longPressGestureRecognizerKey, longPressGestureRecognizer, HLS_ASSOCIATION_WEAK_NONATOMIC);
    }
    return previewingViewController;
}

static void swizzle_unregisterForPreviewingWithContext(UIViewController *self, SEL _cmd, id<UIViewControllerPreviewing> context)
{
    s_unregisterForPreviewingWithContext(self, _cmd, context);
    
    // No need to remove from the set. The unregistered previewing delegates will be used no more and deallocated with
    // the view controller
}
