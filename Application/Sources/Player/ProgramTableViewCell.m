//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ProgramTableViewCell.h"

#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <Lottie/Lottie-Swift.h>
#import <Masonry/Masonry.h>
#import <SRGAppearance/SRGAppearance.h>

@interface ProgramTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIView *thumbnailWrapperView;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UIView *disabledOverlayView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UIView *waveformView;

@property (nonatomic, strong) CompatibleAnimationView *waveformCompatibleAnimationView;
@end

@implementation ProgramTableViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.thumbnailWrapperView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
    self.thumbnailWrapperView.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.thumbnailWrapperView.layer.masksToBounds = YES;
    
    self.disabledOverlayView.hidden = YES;
    self.progressView.progressTintColor = UIColor.play_progressRedColor;
    
    self.waveformCompatibleAnimationView = [[CompatibleAnimationView alloc] initWithCompatibleAnimation:[[CompatibleAnimation alloc] initWithName:@"waveform" bundle:NSBundle.mainBundle]];
    self.waveformCompatibleAnimationView.contentMode = UIViewContentModeScaleAspectFit;
    self.waveformCompatibleAnimationView.tintColor = UIColor.whiteColor;
    [self.waveformView addSubview:self.waveformCompatibleAnimationView];
    
    [self.waveformCompatibleAnimationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.waveformView);
    }];
    
    self.waveformCompatibleAnimationView.loopAnimationCount = -1;
    
    self.waveformView.hidden = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.progressView.hidden = YES;
    
    [self.thumbnailImageView play_resetImage];
    
    self.playing = NO;
    [self setSelected:NO animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    self.waveformView.hidden = ! selected;

    [self updateWaveformAnimation];    
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.program.title;
}

- (NSString *)accessibilityHint
{
    return PlaySRGAccessibilityLocalizedString(@"Plays from the beginning.", @"Program cell hint");
}

#pragma mark Getters and setters

- (void)setProgram:(SRGProgram *)program
{
    _program = program;
    
    self.titleLabel.text = program.title;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    
    self.subtitleLabel.font = [UIFont srg_lightFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    [self.thumbnailImageView play_requestImageForObject:program withScale:ImageScaleSmall type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia];
    
    if ([NSDate.date compare:program.startDate] == NSOrderedAscending) {
        self.titleLabel.textColor = UIColor.play_grayColor;
        
        self.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"At %1$@", @"Introductory text for next program information"), [NSDateFormatter.play_timeFormatter stringFromDate:program.startDate]];
        self.subtitleLabel.textColor = UIColor.play_grayColor;
        
        self.disabledOverlayView.hidden = NO;
        self.userInteractionEnabled = NO;
    }
    else {
        self.titleLabel.textColor = UIColor.whiteColor;
        
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@ - %@", [NSDateFormatter.play_timeFormatter stringFromDate:program.startDate], [NSDateFormatter.play_timeFormatter stringFromDate:program.endDate]];
        self.subtitleLabel.textColor = UIColor.whiteColor;
        
        self.disabledOverlayView.hidden = YES;
        self.userInteractionEnabled = YES;
    }
}

- (void)setProgress:(NSNumber *)progress
{
    if (progress) {
        self.progressView.hidden = NO;
        self.progressView.progress = progress.floatValue;
    }
    else {
        self.progressView.hidden = YES;
    }
}

- (void)setPlaying:(BOOL)playing
{
    _playing = playing;
    [self updateWaveformAnimation];
}

#pragma mark UI

- (void)updateWaveformAnimation
{
    if (self.playing) {
        [self.waveformCompatibleAnimationView play];
    }
    else {
        [self.waveformCompatibleAnimationView pause];
    }
}

@end
