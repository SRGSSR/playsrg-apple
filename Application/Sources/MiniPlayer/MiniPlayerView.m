//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MiniPlayerView.h"

#import "ApplicationConfiguration.h"
#import "MediaPlayerViewController.h"
#import "PlayMiniPlayerView.h"
#import "GoogleCastMiniPlayerView.h"
#import "UIColor+PlaySRG.h"
#import "UIVisualEffectView+PlaySRG.h"

@import GoogleCast;
@import libextobjc;
@import MAKVONotificationCenter;

@interface MiniPlayerView ()

@property (nonatomic, weak) PlayMiniPlayerView *playMiniPlayerView;
@property (nonatomic, weak) GoogleCastMiniPlayerView *googleCastMiniPlayerView;
@property (nonatomic, getter=isActive) BOOL active;

@end

@implementation MiniPlayerView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        UIVisualEffectView *blurView = UIVisualEffectView.play_blurView;
        [self addSubview:blurView];
        
        blurView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [blurView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
        ]];
        
        PlayMiniPlayerView *playMiniPlayerView = PlayMiniPlayerView.view;
        [self addSubview:playMiniPlayerView];
        self.playMiniPlayerView = playMiniPlayerView;
        
        playMiniPlayerView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [playMiniPlayerView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [playMiniPlayerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [playMiniPlayerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [playMiniPlayerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
        ]];
        
        @weakify(self)
        [self.playMiniPlayerView addObserver:self keyPath:@keypath(PlayMiniPlayerView.new, media) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateLayoutAnimated:YES];
        }];
        
        GoogleCastMiniPlayerView *googleCastMiniPlayerView = GoogleCastMiniPlayerView.view;
        [self addSubview:googleCastMiniPlayerView];
        self.googleCastMiniPlayerView = googleCastMiniPlayerView;
        
        googleCastMiniPlayerView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [googleCastMiniPlayerView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [googleCastMiniPlayerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [googleCastMiniPlayerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [googleCastMiniPlayerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
        ]];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(googleCastStateDidChange:)
                                                   name:kGCKCastStateDidChangeNotification
                                                 object:nil];
        
        [self updateLayoutAnimated:NO];
    }
    return self;
}

#pragma mark Subview management

- (void)updateLayoutAnimated:(BOOL)animated
{
    BOOL isGoogleCastConnected = [GCKCastContext sharedInstance].sessionManager.connectionState == GCKConnectionStateConnected;
    BOOL hasMedia = self.playMiniPlayerView.media != nil;
    
    self.active = isGoogleCastConnected || hasMedia;
    
    void (^animations)(void) = ^{
        if (isGoogleCastConnected) {
            self.playMiniPlayerView.alpha = 0.f;
            self.googleCastMiniPlayerView.alpha = 1.f;
        }
        else if (hasMedia) {
            self.playMiniPlayerView.alpha = 1.f;
            self.googleCastMiniPlayerView.alpha = 0.f;
        }
        else {
            self.playMiniPlayerView.alpha = 0.f;
            self.googleCastMiniPlayerView.alpha = 0.f;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    }
    else {
        animations();
    }
}

#pragma mark Notifications

- (void)mediaPlayerViewControllerVisibilityDidChange:(NSNotification *)notification
{
    [self updateLayoutAnimated:YES];
}

- (void)googleCastStateDidChange:(NSNotification *)notification
{
    [self updateLayoutAnimated:YES];
}

@end
