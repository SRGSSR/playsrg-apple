//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LiveAccessView.h"

#import "ApplicationSettings.h"
#import "LiveAccessButton.h"
#import "UIColor+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGLetterbox/SRGLetterbox.h>
#import <Masonry/Masonry.h>

static void commonInit(LiveAccessView *self);

@interface LiveAccessView ()

@property (nonatomic, weak) UIStackView *stackView;

@property (nonatomic, assign) SRGMediaType mediaType;
@property (nonatomic) NSArray<SRGMedia *> *medias;

@property (nonatomic) SRGRequestQueue *requestQueue;

@end

@implementation LiveAccessView

#pragma mark Class methods

+ (CGFloat)height
{
    return 64.f;
}

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Public methods

- (void)refreshWithMediaType:(SRGMediaType)mediaType withCompletionBlock:(void (^)(NSError * _Nullable error))completionBlock
{
    if (mediaType != self.mediaType) {
        for (UIView *arrangedSubview in self.stackView.arrangedSubviews) {
            [arrangedSubview removeFromSuperview];
        }
        
        self.mediaType = SRGMediaTypeNone;
        self.medias = nil;
    }
    
    [self.requestQueue cancel];
    
    if (mediaType != SRGMediaTypeAudio) {
        completionBlock ? completionBlock(nil) : nil;
        return;
    }
    
    NSMutableArray<SRGMedia *> *livestreamMedias = [NSMutableArray array];
    
    @weakify(self)
    self.requestQueue = [[SRGRequestQueue alloc] initWithStateChangeBlock:^(BOOL finished, NSError * _Nullable error) {
        @strongify(self)
        
        if (! finished) {
            return;
        }
        
        if (error) {
            completionBlock ? completionBlock(error) : nil;
            return;
        }
        
        for (UIView *arrangedSubview in self.stackView.arrangedSubviews) {
            [arrangedSubview removeFromSuperview];
        }
        
        self.mediaType = mediaType;
        self.medias = livestreamMedias.copy;
        
        for (SRGMedia *media in livestreamMedias) {
            LiveAccessButton *liveAccessButton = [LiveAccessButton buttonWithType:UIButtonTypeCustom];
            liveAccessButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            liveAccessButton.adjustsImageWhenHighlighted = NO;
            liveAccessButton.accessibilityTraits = UIAccessibilityTraitButton;
            liveAccessButton.media = media;
            liveAccessButton.highlightedBackgroundColor = UIColor.play_grayButtonBackgroundColor;
            
            [liveAccessButton addTarget:self action:@selector(playLive:) forControlEvents:UIControlEventTouchUpInside];
            [self.stackView addArrangedSubview:liveAccessButton];
            
            if ([media isEqual:self.medias.firstObject]) {
                liveAccessButton.leftSeparatorHidden = YES;
            }
            if ([media isEqual:self.medias.lastObject]) {
                liveAccessButton.rightSeparatorHidden = YES;
            }
        }
        [self updateLiveAccessButtonsSelection];
        
        completionBlock ? completionBlock(nil) : nil;
    }];
    
    SRGVendor vendor = ApplicationConfiguration.sharedApplicationConfiguration.vendor;
    SRGRequest *request = [SRGDataProvider.currentDataProvider radioLivestreamsForVendor:vendor contentProviders:SRGContentProvidersDefault withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        @strongify(self)
        
        [self.requestQueue reportError:error];
        [livestreamMedias addObjectsFromArray:medias];
        
        for (SRGMedia *media in medias) {
            NSString *selectedLiveStreamURN = ApplicationSettingSelectedLiveStreamURNForChannelUid(media.channel.uid);
            
            // If a regional stream has been selected by the user, replace the main channel media with it
            if (selectedLiveStreamURN && ! [media.URN isEqual:selectedLiveStreamURN]) {
                SRGRequest *request = [SRGDataProvider.currentDataProvider radioLivestreamsForVendor:vendor channelUid:media.channel.uid withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    [self.requestQueue reportError:error];
                    
                    SRGMedia *selectedMedia = ApplicationSettingSelectedLivestreamMediaForChannelUid(media.channel.uid, medias);
                    if (selectedMedia) {
                        NSInteger index = [livestreamMedias indexOfObject:media];
                        NSAssert(index != NSNotFound, @"Media must be found in array by construction");
                        [livestreamMedias replaceObjectAtIndex:index withObject:selectedMedia];
                    }
                }];
                [self.requestQueue addRequest:request resume:YES];
            }
        }
    }];
    [self.requestQueue addRequest:request resume:YES];
}

- (void)updateLiveAccessButtonsSelection
{
    SRGMedia *media = self.letterboxController.media;
    for (LiveAccessButton *liveAccessButton in self.stackView.arrangedSubviews) {
        liveAccessButton.selected = (media.contentType == SRGContentTypeLivestream
                                        && ([media.uid isEqualToString:liveAccessButton.media.uid] || [media.channel.uid isEqualToString:liveAccessButton.media.channel.uid]));
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (! newWindow) {
        [self.requestQueue cancel];
    }
}

#pragma mark Actions

- (void)playLive:(id)sender
{
    NSUInteger index = [self.stackView.arrangedSubviews indexOfObject:sender];
    if (index == NSNotFound) {
        return;
    }
    
    LiveAccessButton *liveAccessButton = self.stackView.arrangedSubviews[index];
    [self.letterboxController playMedia:liveAccessButton.media atPosition:nil withPreferredSettings:ApplicationSettingPlaybackSettings()];
    
    [self updateLiveAccessButtonsSelection];
}

@end

static void commonInit(LiveAccessView *self)
{
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    [self addSubview:blurView];
    
    [blurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    UIStackView *stackView = [[UIStackView alloc] initWithFrame:self.bounds];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.spacing = 0.f;
    
    [self addSubview:stackView];
    self.stackView = stackView;
    
    [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.left.equalTo(self);
        make.right.equalTo(self);
        make.height.equalTo(@(LiveAccessView.height));
    }];
}
