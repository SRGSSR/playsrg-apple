//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ProgramTableViewCell.h"

#import <SRGAppearance/SRGAppearance.h>

@interface ProgramTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation ProgramTableViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
}

#pragma mark Getters and setters

- (void)setProgram:(SRGProgram *)program
{
    _program = program;
    
    self.titleLabel.text = program.title;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
}

@end
