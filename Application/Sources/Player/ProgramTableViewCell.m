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

#import <SRGAppearance/SRGAppearance.h>

@interface ProgramTableViewCell ()

@property (nonatomic) SRGProgram *program;
@property (nonatomic, getter=isPlaying) BOOL playing;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIView *thumbnailWrapperView;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UIView *disabledOverlayView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UIImageView *waveformImageView;

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
    
    [self.waveformImageView play_setWaveformAnimation34WithTintColor:UIColor.whiteColor];
    self.waveformImageView.hidden = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.progressView.hidden = YES;
    
    [self.thumbnailImageView play_resetImage];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    self.waveformImageView.hidden = ! selected;
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

#pragma mark Attached data

- (void)setProgram:(SRGProgram *)program mediaType:(SRGMediaType)mediaType playing:(BOOL)playing
{
    self.program = program;
    self.playing = playing;
    
    self.titleLabel.text = program.title;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    
    self.subtitleLabel.font = [UIFont srg_lightFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    [self.thumbnailImageView play_requestImageForObject:program withScale:ImageScaleSmall type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia];
    
    if (mediaType == SRGMediaTypeVideo) {
        [self.waveformImageView play_setPlayAnimation34WithTintColor:UIColor.whiteColor];
    }
    else {
        [self.waveformImageView play_setWaveformAnimation34WithTintColor:UIColor.whiteColor];
    }
    
    [self updateWaveformAnimation];
}

#pragma mark Progress

- (void)updateProgressForMediaURN:(NSString *)mediaURN date:(NSDate *)date dateInterval:(NSDateInterval *)dateInterval
{
    SRGProgram *program = self.program;
    if ([program.mediaURN isEqualToString:mediaURN]) {
        self.progressView.progress = fmaxf(fminf([date timeIntervalSinceDate:program.startDate] / [program.endDate timeIntervalSinceDate:program.startDate], 1.f), 0.f);
        self.progressView.hidden = NO;
    }
    else {
        self.progressView.hidden = YES;
    }
    
    if ([program.startDate compare:dateInterval.startDate] == NSOrderedAscending) {
        self.titleLabel.textColor = UIColor.play_grayColor;
        
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@ - %@", [NSDateFormatter.play_timeFormatter stringFromDate:program.startDate], [NSDateFormatter.play_timeFormatter stringFromDate:program.endDate]];
        self.subtitleLabel.textColor = UIColor.play_grayColor;
        
        self.disabledOverlayView.hidden = NO;
        self.userInteractionEnabled = NO;
    }
    else if ([dateInterval.endDate compare:program.startDate] == NSOrderedAscending) {
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

#pragma mark UI

- (void)updateWaveformAnimation
{
    if (self.playing) {
        [self.waveformImageView startAnimating];
    }
    else {
        [self.waveformImageView stopAnimating];
    }
}

@end
