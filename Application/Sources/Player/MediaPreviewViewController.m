//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPreviewViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "Banner.h"
#import "ChannelService.h"
#import "Download.h"
#import "GoogleCast.h"
#import "History.h"
#import "MediaPlayerViewController.h"
#import "PlayErrors.h"
#import "PlaySRG-Swift.h"
#import "SRGDataProvider+PlaySRG.h"
#import "SRGMediaComposition+PlaySRG.h"
#import "UIImageView+PlaySRG.h"
#import "UIView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"
#import "WatchLater.h"

@import SRGAnalyticsDataProvider;
@import SRGAppearance;
@import SRGMediaPlayer;

@interface MediaPreviewViewController ()

@property (nonatomic) SRGMedia *media;
@property (nonatomic) SRGProgramComposition *programComposition;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;      // top object, strong
@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@property (nonatomic, weak) IBOutlet UIStackView *mediaInfoStackView;
@property (nonatomic, weak) IBOutlet UILabel *showLabel;
@property (nonatomic, weak) IBOutlet UILabel *summaryLabel;

@property (nonatomic, weak) IBOutlet UIStackView *channelInfoStackView;
@property (nonatomic, weak) IBOutlet UILabel *programTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *channelLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *playerAspectRatioConstraint;

@property (nonatomic) BOOL shouldRestoreServicePlayback;
@property (nonatomic, copy) NSString *previousAudioSessionCategory;

@property (nonatomic, weak) id channelObserver;

@end

@implementation MediaPreviewViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedia:(SRGMedia *)media
{
    if (self = [self initFromStoryboard]) {
        self.media = media;
    }
    return self;
}

- (instancetype)initFromStoryboard
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    return storyboard.instantiateInitialViewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Will restore playback iff a controller attached to the service was actually playing content before (ignore
    // other running playback playback states, like stalled or seeking, since such cases are not really relevant and
    // cannot be restored anyway as is)
    SRGLetterboxController *serviceController = SRGLetterboxService.sharedService.controller;
    if (serviceController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
        [serviceController pause];
        self.shouldRestoreServicePlayback = YES;
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(mediaMetadataDidChange:)
                                               name:SRGLetterboxMetadataDidChangeNotification
                                             object:self.letterboxController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentSizeCategoryDidChange:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    
    self.letterboxController.contentURLOverridingBlock = ^(NSString *URN) {
        Download *download = [Download downloadForURN:URN];
        return download.localMediaFileURL;
    };
    ApplicationConfigurationApplyControllerSettings(self.letterboxController);
    
    [self.letterboxController prepareToPlayMedia:self.media atPosition:HistoryResumePlaybackPositionForMedia(self.media) withPreferredSettings:ApplicationSettingPlaybackSettings() completionHandler:^{
        if (![UserConsentHelper isShowingBanner]) {
            [self.letterboxController play];
        }
    }];
    [self.letterboxView setUserInterfaceHidden:YES animated:NO togglable:NO];
    [self.letterboxView setTimelineAlwaysHidden:YES animated:NO];
    
    [self updateFonts];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self play_isMovingToParentViewController]) {
        // Ajust preview size for better readability on phones. The default content size works fine on iPads.
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            CGSize screenSize = UIScreen.mainScreen.bounds.size;
            BOOL isPortrait = screenSize.height > screenSize.width;
            CGFloat factor = isPortrait ? 2.5f : 1.f;
            
            CGFloat width = CGRectGetWidth(self.view.frame);
            self.preferredContentSize = CGSizeMake(width, factor * 9.f / 16.f * width);
            
            if (self.media.contentType == SRGContentTypeLivestream && self.media.channel) {
                self.channelObserver = [ChannelService.sharedService addObserverForUpdatesWithChannel:self.media.channel livestreamUid:self.media.uid block:^(SRGProgramComposition * _Nullable programComposition) {
                    self.programComposition = programComposition;
                    [self reloadData];
                }];
            }
            [self reloadData];
        }
        
        self.previousAudioSessionCategory = [AVAudioSession sharedInstance].category;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    
    if (self.letterboxController.mediaComposition) {
        [self srg_trackPageView];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self play_isMovingFromParentViewController]) {
        [ChannelService.sharedService removeObserver:self.channelObserver];
        
        // Restore playback on exit. Result is better with a small delay.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.shouldRestoreServicePlayback) {
                [[AVAudioSession sharedInstance] setCategory:self.previousAudioSessionCategory error:nil];
                if (![UserConsentHelper isShowingBanner]) {
                    [SRGLetterboxService.sharedService.controller play];
                }
            }
        });
    }
}

#pragma mark Data

- (void)reloadData
{
    SRGChannel *channel = self.programComposition.channel;
    if (channel) {
        [self.mediaInfoStackView play_setHidden:YES];
        [self.channelInfoStackView play_setHidden:NO];
        
        SRGProgram *currentProgram = [self.programComposition play_programAt:NSDate.date];
        if (currentProgram) {
            self.titleLabel.text = currentProgram.title;
            
            self.channelLabel.font = [SRGFont fontWithStyle:SRGFontStyleSubtitle1];
            self.channelLabel.text = channel.title;
            
            // Unbreakable spaces before / after the separator
            self.programTimeLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
            self.programTimeLabel.text = [NSString stringWithFormat:@"%@ - %@", [NSDateFormatter.play_time stringFromDate:currentProgram.startDate], [NSDateFormatter.play_time stringFromDate:currentProgram.endDate]];
        }
        else {
            self.titleLabel.text = channel.title;
            self.channelLabel.text = nil;
            self.programTimeLabel.text = nil;
        }
    }
    else {
        self.titleLabel.text = self.media.title;
        self.showLabel.text = (self.media.show.title && ! [self.media.title containsString:self.media.show.title]) ? self.media.show.title : nil;
        
        [self.mediaInfoStackView play_setHidden:NO];
        [self.channelInfoStackView play_setHidden:YES];
        
        self.summaryLabel.text = self.media.play_fullSummary;
    }
}

#pragma mark UI

- (void)updateFonts
{
    self.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleH2];
    self.showLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
    self.summaryLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
    
    self.programTimeLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
    self.channelLabel.font = [SRGFont fontWithStyle:SRGFontStyleSubtitle1];
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitlePlayer;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelPreview ];
}

#pragma mark SRGLetterboxViewDelegate protocol

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, BOOL minimal, CGFloat aspecRatio, CGFloat heightOffset) {
        self.playerAspectRatioConstraint = [self.playerAspectRatioConstraint srg_replacementConstraintWithMultiplier:fminf(1.f / aspecRatio, 1.f) constant:heightOffset];
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    // Automatically resumes playback since we have no controls
    [self.letterboxController togglePlayPause];
}

- (void)mediaMetadataDidChange:(NSNotification *)notification
{
    [self reloadData];
    
    // Notify page view when the full-length changes.
    SRGMediaComposition *previousMediaComposition = notification.userInfo[SRGLetterboxPreviousMediaCompositionKey];
    SRGMediaComposition *mediaComposition = notification.userInfo[SRGLetterboxMediaCompositionKey];
    
    if (self.play_viewVisible && mediaComposition && ! [mediaComposition.fullLengthMedia isEqual:previousMediaComposition.fullLengthMedia]) {
        [self srg_trackPageView];
    }
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self updateFonts];
}

@end
