//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RelatedContentView.h"

#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "UIApplication+PlaySRG.h"
#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface RelatedContentView ()

@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end

@implementation RelatedContentView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_cardGrayBackgroundColor;
    self.layer.cornerRadius = LayoutStandardViewCornerRadius;
}

#pragma mark Getters and setters

- (void)setRelatedContent:(SRGRelatedContent *)relatedContent
{
    _relatedContent = relatedContent;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:relatedContent.title
                                                                                       attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle],
                                                                                                     NSForegroundColorAttributeName : UIColor.whiteColor }];
    
    NSString *text = relatedContent.lead ?: relatedContent.summary;
    if (text.length != 0) {
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" - %@", text]
                                                                               attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle],
                                                                                             NSForegroundColorAttributeName : UIColor.play_lightGrayColor }]];
    }
    
    self.textLabel.attributedText = attributedText.copy;
}

- (IBAction)openLink:(id)sender
{
    NSURL *URL = self.relatedContent.URL;
    if (URL) {
        if (! [UIApplication.sharedApplication.delegate application:UIApplication.sharedApplication
                                                            openURL:URL
                                                            options:@{ UIApplicationOpenURLOptionsOpenInPlaceKey : @NO,
                                                                       UIApplicationOpenURLOptionsSourceApplicationKey : NSBundle.mainBundle.bundleIdentifier }]) {
            [UIApplication.sharedApplication play_openURL:URL withCompletionHandler:nil];
        }
    }
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.relatedContent.title;
}

- (NSString *)accessibilityHint
{
    return PlaySRGAccessibilityLocalizedString(@"Opens in Safari.", @"Hint for content opened in Safari");
}

@end
