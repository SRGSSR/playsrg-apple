//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SongTableViewCell.h"

#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SongTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *artistLabel;

@end

@implementation SongTableViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_cardGrayBackgroundColor;
}

#pragma mark Getters and setters

- (void)setSong:(SRGSong *)song
{
    _song = song;
    
    self.timeLabel.text = [NSDateFormatter.play_timeFormatter stringFromDate:song.date];
    self.timeLabel.font = [UIFont srg_lightFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    self.titleLabel.text = song.title;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    
    self.artistLabel.text = song.artist.name;
    self.artistLabel.font = [UIFont srg_regularFontWithTextStyle:SRGAppearanceFontTextStyleBody];
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    
    if (enabled) {
        self.timeLabel.textColor = UIColor.whiteColor;
        self.titleLabel.textColor = UIColor.whiteColor;
        self.artistLabel.textColor = UIColor.play_grayColor;
        self.userInteractionEnabled = YES;
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else {
        self.timeLabel.textColor = UIColor.play_grayColor;
        self.titleLabel.textColor = UIColor.play_grayColor;
        self.artistLabel.textColor = UIColor.play_grayColor;
        self.userInteractionEnabled = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
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

@end
