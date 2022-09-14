//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayMiniPlayerView.h"

#import "AccessibilityView.h"
#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "Banner.h"
#import "ChannelService.h"
#import "GoogleCast.h"
#import "History.h"
#import "MediaPlayerViewController.h"
#import "NSBundle+PlaySRG.h"
#import "SRGLetterboxController+PlaySRG.h"
#import "SRGProgram+PlaySRG.h"
#import "SRGProgramComposition+PlaySRG.h"
#import "UIView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import MAKVONotificationCenter;
@import SRGAppearance;
@import SRGLetterbox;
@import libextobjc;

@interface PlayMiniPlayerView () <AccessibilityViewDelegate, SRGPlaybackButtonDelegate>

@property (nonatomic) SRGMedia *media;                                // Latest media
@property (nonatomic) SRGProgramComposition *programComposition;      // Latest program information, if any

@property (nonatomic) SRGLetterboxController *controller;

@property (nonatomic, weak) IBOutlet AccessibilityView *accessibilityView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@property (nonatomic, weak) IBOutlet SRGPlaybackButton *playbackButton;
@property (nonatomic, weak) IBOutlet UILabel *liveLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;

@property (nonatomic, weak) id periodicTimeObserver;
@property (nonatomic, weak) id channelObserver;

@end

@implementation PlayMiniPlayerView

#pragma mark Class methods

+ (PlayMiniPlayerView *)view
{
    static dispatch_once_t s_onceToken;
    static PlayMiniPlayerView *s_view;
    dispatch_once(&s_onceToken, ^{
        s_view = [NSBundle.mainBundle loadNibNamed:NSStringFromClass(self) owner:nil options:nil].firstObject;
    });
    return s_view;
}

#pragma mark Object lifecycle

- (void)dealloc
{
    self.controller = nil;
}

#pragma mark Getters and setters

- (void)setMedia:(SRGMedia *)media
{
    if (media.contentType != SRGContentTypeLivestream || ! [media.channel isEqual:self.programComposition.channel]) {
        self.programComposition = nil;
    }
    
    [self unregisterChannelUpdates];
    _media = media;
    [self registerForChannelUpdatesWithFallbackMedia:media];
}

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller) {
        [self unregisterUserInterfaceUpdatesWithController:_controller];
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGLetterboxMetadataDidChangeNotification
                                                    object:_controller];
    }
    
    _controller = controller;
    
    // Always keep the most recent media information to be able to restart at a later time
    if (controller.media) {
        self.media = controller.media;
    }
    
    [self reloadData];
    
    if (controller) {
        [self registerUserInterfaceUpdatesWithController:controller];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(mediaMetadataDidChange:)
                                                   name:SRGLetterboxMetadataDidChangeNotification
                                                 object:controller];
    }
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.titleLabel.text = nil;
    
    self.progressView.progress = 0.f;
    self.progressView.progressTintColor = UIColor.redColor;
    
    self.playbackButton.delegate = self;
    self.closeButton.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Close", @"Close button label");
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openFullScreenPlayer:)];
    [self addGestureRecognizer:tapGestureRecognizer];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidEnterBackground:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationWillEnterForeground:)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(contentSizeCategoryDidChange:)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(googleCastPlaybackDidStart:)
                                               name:GoogleCastPlaybackDidStartNotification
                                             object:nil];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    SRGLetterboxService *letterboxService = SRGLetterboxService.sharedService;
    
    if (newWindow) {
        // Track service controller changes and tracks the corresponding controller (UI updates will only be triggered
        // when the controller plays audio, though)
        @weakify(self)
        @weakify(letterboxService)
        [letterboxService addObserver:self keyPath:@keypath(letterboxService.controller) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            @strongify(letterboxService)
            
            self.controller = letterboxService.controller;
        }];
        self.controller = letterboxService.controller;
        
        [self reloadData];
        
        [self registerForChannelUpdatesWithFallbackMedia:self.media];
    }
    else {
        [letterboxService removeObserver:self keyPath:@keypath(letterboxService.controller)];
        self.controller = nil;
        
        [self unregisterChannelUpdates];
    }
}

#pragma mark Accessibility

- (NSArray *)accessibilityElements
{
    return @[ self.accessibilityView, self.playbackButton, self.closeButton ];
}

#pragma mark Data

- (void)reloadData
{
    self.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
    
    SRGChannel *channel = self.programComposition.channel;
    if (channel) {
        self.liveLabel.font = [SRGFont fontWithStyle:SRGFontStyleSubtitle1];
        if (! self.controller || self.controller.live) {
            self.titleLabel.numberOfLines = 1;
            self.liveLabel.hidden = NO;
            self.liveLabel.text = NSLocalizedString(@"Live", @"Introductory text for what is currently on air, displayed on the mini player");
        }
        else if (self.media.contentType == SRGContentTypeLivestream || self.media.contentType == SRGContentTypeScheduledLivestream) {
            self.titleLabel.numberOfLines = 1;
            self.liveLabel.hidden = NO;
            self.liveLabel.text = NSLocalizedString(@"Time-shifted", @"Introductory text for live content played with timeshift, displayed on the mini player");
        }
        else {
            self.titleLabel.numberOfLines = 2;
            self.liveLabel.hidden = YES;
        }
    }
    else {
        self.titleLabel.numberOfLines = 2;
        self.liveLabel.hidden = YES;
    }
    
    NSDate *currentDate = self.controller.currentDate ?: NSDate.date;
    SRGProgram *currentProgram = [self.programComposition play_programAtDate:currentDate];
    if (currentProgram) {
        self.titleLabel.text = currentProgram.title;
    }
    else {
        self.titleLabel.text = channel.title ?: self.media.title;
    }
    
    BOOL isLiveOnly = (self.controller.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive);
    self.playbackButton.pauseImage = isLiveOnly ? [UIImage imageNamed:@"stop"] : [UIImage imageNamed:@"pause"];
    
    [self updateProgress];
}

- (void)updateProgress
{
    if ([self.controller.media isEqual:self.media]) {
        NSDate *currentDate = self.controller.currentDate ?: NSDate.date;
        SRGProgram *currentProgram = [self.programComposition play_programAtDate:currentDate];
        if (currentProgram) {
            self.progressView.progress = fmaxf(fminf([currentDate timeIntervalSinceDate:currentProgram.startDate] / [currentProgram.endDate timeIntervalSinceDate:currentProgram.startDate], 1.f), 0.f);
            self.progressView.hidden = NO;
        }
        else if (self.media.contentType == SRGContentTypeLivestream) {
            self.progressView.hidden = YES;
        }
        else {
            CMTimeRange timeRange = self.controller.timeRange;
            CMTime currentTime = self.controller.currentTime;
            
            if (CMTIMERANGE_IS_VALID(timeRange) && ! CMTIMERANGE_IS_EMPTY(timeRange)) {
                self.progressView.progress = CMTimeGetSeconds(CMTimeSubtract(currentTime, timeRange.start)) / CMTimeGetSeconds(timeRange.duration);
            }
            else {
                self.progressView.progress = HistoryPlaybackProgressForMedia(self.media);
            }
            self.progressView.hidden = NO;
        }
    }
    else {
        if (self.media.contentType == SRGContentTypeLivestream) {
            self.progressView.hidden = YES;
        }
        else {
            self.progressView.progress = HistoryPlaybackProgressForMedia(self.media);
            self.progressView.hidden = NO;
        }
    }
}

- (void)updateMetadataWithMedia:(SRGMedia *)media
{
    self.media = media;
    [self reloadData];
}

#pragma mark Controller registration for playback-related UI updates

- (void)registerUserInterfaceUpdatesWithController:(SRGLetterboxController *)controller
{
    self.playbackButton.mediaPlayerController = controller.mediaPlayerController;
    
    @weakify(self)
    self.periodicTimeObserver = [controller addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        [self reloadData];
    }];
    [self reloadData];
}

- (void)unregisterUserInterfaceUpdatesWithController:(SRGLetterboxController *)controller
{
    self.playbackButton.mediaPlayerController = nil;
    [controller removePeriodicTimeObserver:self.periodicTimeObserver];
}

#pragma mark Channel updates

- (SRGMedia *)mainMedia
{
    if (self.controller.mediaComposition) {
        return [self.controller.mediaComposition mediaForSubdivision:self.controller.mediaComposition.mainChapter];
    }
    else {
        return self.controller.media;
    }
}

- (void)registerForChannelUpdatesWithFallbackMedia:(SRGMedia *)fallbackMedia
{
    SRGMedia *mainMedia = [self mainMedia] ?: fallbackMedia;
    if (mainMedia.contentType != SRGContentTypeLivestream || ! mainMedia.channel) {
        return;
    }
    
    [ChannelService.sharedService removeObserver:self.channelObserver];
    self.channelObserver = [ChannelService.sharedService addObserverForUpdatesWithChannel:mainMedia.channel livestreamUid:mainMedia.uid block:^(SRGProgramComposition * _Nullable programComposition) {
        self.programComposition = programComposition;
        [self reloadData];
    }];
}

- (void)unregisterChannelUpdates
{
    [ChannelService.sharedService removeObserver:self.channelObserver];
}

#pragma mark AccessibilityViewDelegate protocol

- (NSString *)labelForAccessibilityView:(AccessibilityView *)accessibilityView
{
    if (! self.media) {
        return nil;
    }
    
    NSString *format = (self.controller.playbackState == SRGMediaPlayerPlaybackStatePlaying) ? PlaySRGAccessibilityLocalizedString(@"Now playing: %@", @"Mini player label") : PlaySRGAccessibilityLocalizedString(@"Recently played: %@", @"Mini player label");
    
    SRGChannel *channel = self.programComposition.channel;
    if (channel) {
        NSMutableString *accessibilityLabel = [NSMutableString stringWithFormat:format, channel.title];
        
        NSDate *currentDate = self.controller.currentDate ?: NSDate.date;
        SRGProgram *currentProgram = [self.programComposition play_programAtDate:currentDate];
        if (currentProgram) {
            [accessibilityLabel appendFormat:@", %@", currentProgram.title];
        }
        return accessibilityLabel.copy;
    }
    else {
        NSMutableString *accessibilityLabel = [NSMutableString stringWithFormat:format, self.media.title];
        if (self.media.show.title && ! [self.media.title containsString:self.media.show.title]) {
            [accessibilityLabel appendFormat:@", %@", self.media.show.title];
        }
        return accessibilityLabel.copy;
    }
}

- (NSString *)hintForAccessibilityView:(AccessibilityView *)accessibilityView
{
    return PlaySRGAccessibilityLocalizedString(@"Opens the full screen player", @"Mini player action hint");
}

#pragma mark SRGPlaybackButtonDelegate protocol

- (void)playbackButton:(SRGPlaybackButton *)playbackButton didPressInState:(SRGPlaybackButtonState)state
{
    SRGMedia *media = self.media;
    if (! media) {
        return;
    }
    
    SRGPosition *position = HistoryResumePlaybackPositionForMedia(media);
    SRGLetterboxController *controller = self.controller;
    
    // If a controller is readily available, use it
    if (controller) {
        if (! [media isEqual:controller.media]) {
            [controller playMedia:media atPosition:position withPreferredSettings:ApplicationSettingPlaybackSettings()];
        }
        else {
            [controller togglePlayPause];
        }
    }
    // Otherwise use a fresh instance and enable it with the service. The mini player observes service controller changes
    // and will automatically be updated
    else {
        controller = [[SRGLetterboxController alloc] init];
        ApplicationConfigurationApplyControllerSettings(controller);
        [controller playMedia:media atPosition:position withPreferredSettings:ApplicationSettingPlaybackSettings()];
        [SRGLetterboxService.sharedService enableWithController:controller pictureInPictureDelegate:nil];
    }
    
    if (state == SRGPlaybackButtonStatePlay && media.mediaType == SRGMediaTypeVideo && ! ApplicationSettingBackgroundVideoPlaybackEnabled()
            && ! AVAudioSession.srg_isAirPlayActive && ! controller.pictureInPictureActive) {
        [self.play_nearestViewController play_presentMediaPlayerFromLetterboxController:controller withAirPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
    }
}

- (NSString *)playbackButton:(SRGPlaybackButton *)playbackButton accessibilityLabelForState:(SRGPlaybackButtonState)state
{
    if (state == SRGPlaybackButtonStatePause) {
        BOOL isLiveOnly = (self.controller.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive);
        return isLiveOnly ? PlaySRGAccessibilityLocalizedString(@"Stop", @"Stop button label") : nil;
    }
    else {
        return nil;
    }
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [SRGLetterboxService.sharedService disableForController:self.controller];
    [self.controller reset];
    
    self.media = nil;
}

#pragma mark Gestures

- (void)openFullScreenPlayer:(UIGestureRecognizer *)gestureRecognizer
{
    SRGMedia *media = self.media;
    if (! media) {
        return;
    }
    
    SRGLetterboxController *controller = self.controller;
    if ([controller.media isEqual:media]) {
        [self.play_nearestViewController play_presentMediaPlayerFromLetterboxController:controller withAirPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
    }
    else {
        [self.play_nearestViewController play_presentMediaPlayerWithMedia:media position:nil airPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
    }
}

#pragma mark Notifications

- (void)mediaMetadataDidChange:(NSNotification *)notification
{
    SRGMedia *media = notification.userInfo[SRGLetterboxMediaKey];
    [self updateMetadataWithMedia:media];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self unregisterUserInterfaceUpdatesWithController:self.controller];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self registerUserInterfaceUpdatesWithController:self.controller];
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self reloadData];
}

- (void)googleCastPlaybackDidStart:(NSNotification *)notification
{
    SRGMedia *media = notification.userInfo[GoogleCastMediaKey];
    [self updateMetadataWithMedia:media];
}

@end
