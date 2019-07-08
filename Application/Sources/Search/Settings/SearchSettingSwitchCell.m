//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingSwitchCell.h"

#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SearchSettingSwitchCell ()

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UISwitch *valueSwitch;

@end

@implementation SearchSettingSwitchCell

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
