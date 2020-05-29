//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SongTableViewCell.h"

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
    
    self.timeLabel.textColor = UIColor.whiteColor;
    self.titleLabel.textColor = UIColor.whiteColor;
    self.artistLabel.textColor = UIColor.play_grayColor;
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

@end
