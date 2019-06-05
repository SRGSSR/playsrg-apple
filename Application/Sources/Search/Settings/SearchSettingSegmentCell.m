//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingSegmentCell.h"

#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SearchSettingSegmentCell ()

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;

@end

@implementation SearchSettingSegmentCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_popoverGrayColor;
    
    self.nameLabel.font = [UIFont srg_mediumFontWithTextStyle:UIFontTextStyleBody];
    self.nameLabel.textColor = UIColor.whiteColor;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

@end
