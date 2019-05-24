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
    
    self.label.font = [UIFont srg_mediumFontWithSize:11.f];
    self.label.text = [NSLocalizedString(@"My List", @"Title displayed in the My List player button") uppercaseString];

}

#pragma mark Getter and Setter

- (void)setFavorited:(BOOL)favorited
{
    _favorited = favorited;
    
    self.mainImageView.image = favorited ? [UIImage imageNamed:@"my_list_full-34"] : [UIImage imageNamed:@"my_list-34"];
    self.statusImageView.image = favorited ? [UIImage imageNamed:@"my_list_added-10"] : [UIImage imageNamed:@"my_list_add-10"];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

- (NSString *)accessibilityLabel
{
    return self.favorited ? PlaySRGAccessibilityLocalizedString(@"Remove from My List", @"Show My List removal label") : PlaySRGAccessibilityLocalizedString(@"Add to My List", @"Show My List creation label");
}

@end
