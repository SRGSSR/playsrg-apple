//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingSelectorCell.h"

#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SearchSettingSelectorCell ()

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@end

@implementation SearchSettingSelectorCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_popoverGrayColor;
    
    self.nameLabel.font = [UIFont srg_mediumFontWithTextStyle:UIFontTextStyleBody];
    self.nameLabel.textColor = UIColor.whiteColor;
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
}

@end
