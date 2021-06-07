//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingTableViewCell.h"

@import SRGAppearance;

@implementation SettingTableViewCell

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    self.textLabel.textColor = highlighted ? UIColor.srg_gray4Color : UIColor.whiteColor;
}

@end
