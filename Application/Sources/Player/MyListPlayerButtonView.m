//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MyListPlayerButtonView.h"

#import "NSBundle+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface MyListPlayerButtonView ()

@property (nonatomic, weak) IBOutlet UIImageView *mainImageView;
@property (nonatomic, weak) IBOutlet UIImageView *statusImageView;

@property (nonatomic, weak) IBOutlet UILabel *label;

@end

@implementation MyListPlayerButtonView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    
    self.label.font = [UIFont srg_mediumFontWithSize:10.f];
    self.label.text = [NSLocalizedString(@"My List", @"Title displayed in the My List player button") uppercaseString];

}

#pragma mark Getter and Setter

- (void)setInMyList:(BOOL)inMyList
{
    _inMyList = inMyList;
    
    self.mainImageView.image = inMyList ? [UIImage imageNamed:@"my_list_full-34"] : [UIImage imageNamed:@"my_list-34"];
    self.statusImageView.image = inMyList ? [UIImage imageNamed:@"my_list_added-10"] : [UIImage imageNamed:@"my_list_add-10"];
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

- (NSString *)accessibilityLabel
{
    return (self.inMyList) ? PlaySRGAccessibilityLocalizedString(@"Remove from My List", @"Show My List removal label") : PlaySRGAccessibilityLocalizedString(@"Add to My List", @"Show My List creation label");
}

@end
