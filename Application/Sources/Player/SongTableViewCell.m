//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SongTableViewCell.h"

#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

static const CGFloat SongTableViewMargin = 42.f;

@interface SongTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *artistLabel;
@property (nonatomic, weak) IBOutlet UIImageView *waveformImageView;

@property (nonatomic, weak) IBOutlet UIView *rightMarginView;
@property (nonatomic, weak) IBOutlet UIView *waveformView;

@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray<NSLayoutConstraint *> *marginWidthConstraints;

@end

@implementation SongTableViewCell

#pragma mark Class methods

+ (UIFont *)timeLabelFont
{
    return [UIFont srg_lightFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

+ (UIFont *)titleLabelFont
{
    return [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
}

+ (UIFont *)artistLabelFont
{
    return [UIFont srg_regularFontWithTextStyle:SRGAppearanceFontTextStyleBody];
}

+ (CGFloat)heightForSong:(SRGSong *)song withCellWidth:(CGFloat)width
{
    // Add variable contribution depending on the number of lines required to properly display a song title
    // (maximum of 2 lines)
    // Remark: We do not take the waveform into account. We namely do not want to change the height of the
    //         cell whether or not the waveform is displayed. We therefore calculate the layout in the nominal
    //         case, i.e. without waveform.
    UIFont *font = [self titleLabelFont];
    CGFloat textWidth = fmaxf(width - 2 * SongTableViewMargin, 0.f);
    CGRect boundingRect = [song.title boundingRectWithSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{ NSFontAttributeName : font }
                                                   context:nil];
    
    CGFloat lineHeight = font.lineHeight;
    NSInteger numberOfLines = MIN(CGRectGetHeight(boundingRect) / lineHeight, 2);
    CGFloat titleHeight = ceil(numberOfLines * lineHeight);
    
    // Time and artist fields are mandatory, a contribution is therefore added for each
    return [self timeLabelFont].lineHeight + [self artistLabelFont].lineHeight + titleHeight;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_cardGrayBackgroundColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.marginWidthConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = SongTableViewMargin;
    }];
    
    self.waveformView.hidden = YES;
    self.rightMarginView.hidden = NO;
    
    [self.waveformImageView play_setWaveformAnimation34WithTintColor:UIColor.whiteColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    self.waveformView.hidden = ! selected;
    self.rightMarginView.hidden = selected;
    
    [self updateWaveformAnimation];
}

#pragma mark Getters and setters

- (void)setSong:(SRGSong *)song
{
    _song = song;
    
    self.timeLabel.text = [NSDateFormatter.play_timeFormatter stringFromDate:song.date];
    self.timeLabel.font = [SongTableViewCell timeLabelFont];
    
    self.titleLabel.text = song.title;
    self.titleLabel.font = [SongTableViewCell titleLabelFont];
    
    self.artistLabel.text = song.artist.name;
    self.artistLabel.font = [SongTableViewCell artistLabelFont];
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    
    if (enabled) {
        self.timeLabel.textColor = UIColor.whiteColor;
        self.titleLabel.textColor = UIColor.whiteColor;
        self.artistLabel.textColor = UIColor.play_grayColor;
        self.userInteractionEnabled = YES;
    }
    else {
        self.timeLabel.textColor = UIColor.play_grayColor;
        self.titleLabel.textColor = UIColor.play_grayColor;
        self.artistLabel.textColor = UIColor.play_grayColor;
        self.userInteractionEnabled = YES;
    }
}

- (void)setPlaying:(BOOL)playing
{
    _playing = playing;
    [self updateWaveformAnimation];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [NSString stringWithFormat:PlaySRGAccessibilityLocalizedString(@"%@, by %@", @"Song description. Firt placeholder is song title, second is artist name"), self.song.title, self.song.artist.name];
}

- (NSString *)accessibilityHint
{
    return self.enabled ? PlaySRGAccessibilityLocalizedString(@"Plays the song.", @"Song cell hint") : nil;
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
