//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SongTableViewCell.h"

#import "NSBundle+PlaySRG.h"
#import "PlaySRG-Swift.h"
#import "UIImageView+PlaySRG.h"

@import SRGAppearance;

static const CGFloat SongTableViewMargin = 42.f;
static const CGFloat SongTableViewWaveformViewWidth = 34.f;
static const CGFloat SongTableViewWaveformViewLeading = 8.f;
static const CGFloat SongTableViewWaveformViewTrailing = 22.f;

@interface SongTableViewCell ()

@property (nonatomic, nullable) SRGSong *song;
@property (nonatomic, getter=isPlaying) BOOL playing;
@property (nonatomic, getter=isPlayable) BOOL playable;

@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *artistLabel;
@property (nonatomic, weak) IBOutlet UIImageView *waveformImageView;

@property (nonatomic, weak) IBOutlet UIView *rightMarginView;
@property (nonatomic, weak) IBOutlet UIView *waveformView;

@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray<NSLayoutConstraint *> *marginWidthConstraints;

@property (nonatomic) IBOutlet NSLayoutConstraint *waveformViewWidthConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *waveformViewLeadingConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *waveformViewTrailingConstraint;

@end

@implementation SongTableViewCell

#pragma mark Class methods

+ (UIFont *)timeLabelFont
{
    return [SRGFont fontWithStyle:SRGFontStyleSubtitle1];
}

+ (UIFont *)titleLabelFont
{
    return [SRGFont fontWithStyle:SRGFontStyleBody];
}

+ (UIFont *)artistLabelFont
{
    return [SRGFont fontWithStyle:SRGFontStyleSubtitle1];
}

+ (CGFloat)heightForSong:(SRGSong *)song withCellWidth:(CGFloat)width
{
    // Add variable contribution depending on the number of lines required to properly display a song title
    // (maximum of 2 lines)
    // Remark: We namely do not want to change the height of the cell whether or not the waveform is displayed. We
    //         therefore calculate the layout in the nominal case, i.e. without waveform.
    return [self heightForSong:song withCellWidth:width waveformDisplayed:NO];
}

+ (CGFloat)heightForSong:(SRGSong *)song withCellWidth:(CGFloat)width waveformDisplayed:(BOOL)waveformDisplayed
{
    UIFont *font = [self titleLabelFont];
    CGFloat textMargins = waveformDisplayed ? SongTableViewMargin + SongTableViewWaveformViewLeading + SongTableViewWaveformViewWidth + SongTableViewWaveformViewTrailing : 2 * SongTableViewMargin;
    CGFloat textWidth = fmaxf(width - textMargins, 0.f);
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

+ (NSInteger)titleNumberOfLinesForSong:(SRGSong *)song withCellWidth:(CGFloat)width
{
    return [self heightForSong:song withCellWidth:width waveformDisplayed:NO] == [self heightForSong:song withCellWidth:width waveformDisplayed:YES] ? 2 : 1;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.srg_gray23Color;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.marginWidthConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = SongTableViewMargin;
    }];
    
    self.waveformViewWidthConstraint.constant = SongTableViewWaveformViewWidth;
    self.waveformViewLeadingConstraint.constant = SongTableViewWaveformViewLeading;
    self.waveformViewTrailingConstraint.constant = SongTableViewWaveformViewTrailing;
    
    self.waveformView.hidden = YES;
    self.rightMarginView.hidden = NO;
    
    [self.waveformImageView play_setWaveformAnimationWithTintColor:UIColor.whiteColor];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(copySongToPasteboard:)];
    [self addGestureRecognizer:longPressGestureRecognizer];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    self.waveformView.hidden = ! selected;
    self.rightMarginView.hidden = selected;
    
    [self updateWaveformAnimation];
}

#pragma mark Attached data

- (void)setSong:(SRGSong *)song playing:(BOOL)playing withCellWidth:(CGFloat)width
{
    self.song = song;
    self.playing = playing;
    
    self.timeLabel.text = [NSDateFormatter.play_time stringFromDate:song.date];
    self.timeLabel.font = [SongTableViewCell timeLabelFont];
    
    self.titleLabel.numberOfLines = [SongTableViewCell titleNumberOfLinesForSong:song withCellWidth:width];
    self.titleLabel.text = song.title;
    self.titleLabel.font = [SongTableViewCell titleLabelFont];
    
    self.artistLabel.text = song.artist.name;
    self.artistLabel.font = [SongTableViewCell artistLabelFont];
    
    [self updateWaveformAnimation];
}

- (void)updateProgressForDateInterval:(NSDateInterval *)dateInterval
{
    if ([dateInterval containsDate:self.song.date]) {
        self.timeLabel.textColor = UIColor.whiteColor;
        self.titleLabel.textColor = UIColor.whiteColor;
        self.artistLabel.textColor = UIColor.srg_gray96Color;
        self.playable = YES;
    }
    else {
        self.timeLabel.textColor = UIColor.srg_gray96Color;
        self.titleLabel.textColor = UIColor.srg_gray96Color;
        self.artistLabel.textColor = UIColor.srg_gray96Color;
        self.playable = NO;
    }
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [NSString stringWithFormat:PlaySRGAccessibilityLocalizedString(@"%1$@, by %2$@", @"Song description. First placeholder is song title, second is artist name"), self.song.title, self.song.artist.name];
}

- (NSString *)accessibilityHint
{
    return self.playable ? PlaySRGAccessibilityLocalizedString(@"Plays the music.", @"Song cell hint") : nil;
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

#pragma mark Actions

- (void)copySongToPasteboard:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan && self.song) {
        [UIPasteboard.generalPasteboard setString:[NSString stringWithFormat:@"%@, %@", self.song.title, self.song.artist.name]];
        
        [Banner showWith:BannerStyleInfo
                 message:NSLocalizedString(@"The content has been copied to the clipboard.", @"Message displayed when song title and artist name have been copied to the pasteboard")
                   image:nil
                  sticky:NO];
    }
}

@end
