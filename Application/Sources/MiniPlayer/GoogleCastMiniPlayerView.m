//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "GoogleCastMiniPlayerView.h"

#import "AccessibilityView.h"
#import "AnalyticsConstants.h"
#import "GoogleCastPlaybackButton.h"
#import "NSBundle+PlaySRG.h"
#import "UIWindow+PlaySRG.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

@interface GoogleCastMiniPlayerView () <AccessibilityViewDelegate>

@property (nonatomic) GCKUIMediaController *controller;

@property (nonatomic, weak) IBOutlet AccessibilityView *accessibilityView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet GoogleCastPlaybackButton *playbackButton;
@property (nonatomic, weak) IBOutlet UILabel *liveLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation GoogleCastMiniPlayerView

#pragma mark Class methods

+ (GoogleCastMiniPlayerView *)view
{
    return [NSBundle.mainBundle loadNibNamed:NSStringFromClass(self) owner:nil options:nil].firstObject;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self updateFonts];
    
    self.controller = [[GCKUIMediaController alloc] init];
    self.controller.delegate = self;
    
    self.controller.playPauseToggleButton = self.playbackButton;
    self.controller.streamProgressView = self.progressView;
    
    self.progressView.progress = 0.f;
    self.progressView.progressTintColor = UIColor.redColor;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openFullScreenPlayer:)];
    [self addGestureRecognizer:tapGestureRecognizer];
    
    [self.playbackButton setImage:[UIImage imageNamed:@"pause-50"] forButtonState:GCKUIButtonStatePlay];
    [self.playbackButton setImage:[UIImage imageNamed:@"pause-50"] forButtonState:GCKUIButtonStatePlayLive];
    [self.playbackButton setImage:[UIImage imageNamed:@"play-50"] forButtonState:GCKUIButtonStatePause];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(contentSizeCategoryDidChange:)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self reloadData];
    }
}

#pragma mark Data

- (void)reloadData
{
    // We don't bind properties to the controller (which would have been easier) since we want to display custom information
    // when those are empty.
    // Remark: Do not use controller.session which, probably because of a bug, is not updated to point at the current session
    //         if created before it. Its progress still reflects the one of the current session media, though.
    GCKSession *session = [GCKCastContext sharedInstance].sessionManager.currentSession;
    GCKMediaInformation *mediaInformation = session.remoteMediaClient.mediaStatus.mediaInformation;
    if (mediaInformation.streamType == GCKMediaStreamTypeLive) {
        self.liveLabel.hidden = NO;
        self.liveLabel.text = NSLocalizedString(@"Currently", @"Introductory text for what is currently on air, displayed on the mini player");
    }
    else {
        self.liveLabel.hidden = YES;
    }
    
    GCKMediaMetadata *metadata = mediaInformation.metadata;
    if (metadata) {
        self.titleLabel.text = [metadata stringForKey:kGCKMetadataKeyTitle];
    }
    else {
        NSString *deviceName = session.device.friendlyName;
        if (deviceName) {
            self.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ is idle.", @"Title displayed when no media is being played on the connected Google Cast receiver (placeholder is the device name)"), deviceName];
        }
        else {
            self.titleLabel.text = NSLocalizedString(@"Receiver is idle.", @"Title displayed when no media is being played on the connected Google Cast receiver (name unknown)");
        }
    }
}

#pragma mark Fonts

- (void)updateFonts
{
    self.liveLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
}

#pragma mark Accessibility

- (NSArray *)accessibilityElements
{
    return @[ self.accessibilityView, self.playbackButton ];
}

#pragma mark AccessibilityViewDelegate protocol

- (NSString *)labelForAccessibilityView:(AccessibilityView *)accessibilityView
{
    return self.titleLabel.text;
}

- (NSString *)hintForAccessibilityView:(AccessibilityView *)accessibilityView
{
    return PlaySRGAccessibilityLocalizedString(@"Plays the content.", @"Mini player action hint");
}

#pragma mark GCKUIMediaControllerDelegate protocol

- (void)mediaController:(GCKUIMediaController *)mediaController didUpdatePlayerState:(GCKMediaPlayerState)playerState lastStreamPosition:(NSTimeInterval)streamPosition
{
    [self reloadData];
}

#pragma mark Gestures

- (void)openFullScreenPlayer:(UIGestureRecognizer *)gestureRecognizer
{
    GCKSession *session = [GCKCastContext sharedInstance].sessionManager.currentSession;
    GCKMediaInformation *mediaInformation = session.remoteMediaClient.mediaStatus.mediaInformation;
    if (mediaInformation) {
        // Do not use -[GCKCastContext presentDefaultExpandedMediaControls] so that we can control the presentation style
        GCKUIExpandedMediaControlsViewController *mediaControlsViewController = [GCKCastContext sharedInstance].defaultExpandedMediaControlsViewController;
        mediaControlsViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [UIApplication.sharedApplication.keyWindow.play_topViewController presentViewController:mediaControlsViewController animated:YES completion:nil];
        [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:AnalyticsPageTitlePlayer levels:@[ AnalyticsPageLevelPlay, AnalyticsPageLevelGoogleCast ]];
    }
    else {
        [[GCKCastContext sharedInstance] presentCastDialog];
        [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:AnalyticsPageTitleDevices levels:@[ AnalyticsPageLevelPlay, AnalyticsPageLevelGoogleCast ]];
    }
}

#pragma mark Notifications

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self updateFonts];
}

@end
