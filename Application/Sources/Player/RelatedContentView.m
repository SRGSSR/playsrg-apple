//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RelatedContentView.h"

#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "UIApplication+PlaySRG.h"

@import SRGAppearance;

@interface RelatedContentView ()

@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end

@implementation RelatedContentView

#pragma mark Class methods

+ (RelatedContentView *)view
{
    return [NSBundle.mainBundle loadNibNamed:NSStringFromClass(self) owner:nil options:nil].firstObject;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.srg_gray23Color;
    self.layer.cornerRadius = LayoutStandardViewCornerRadius;
}

#pragma mark Getters and setters

- (void)setRelatedContent:(SRGRelatedContent *)relatedContent
{
    _relatedContent = relatedContent;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:relatedContent.title
                                                                                       attributes:@{ NSFontAttributeName : [SRGFont fontWithStyle:SRGFontStyleSubtitle1],
                                                                                                     NSForegroundColorAttributeName : UIColor.whiteColor }];
    
    NSString *text = relatedContent.lead ?: relatedContent.summary;
    if (text.length != 0) {
        // Unbreakable spaces before / after the separator
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" - %@", text]
                                                                               attributes:@{ NSFontAttributeName : [SRGFont fontWithStyle:SRGFontStyleSubtitle1],
                                                                                             NSForegroundColorAttributeName : UIColor.srg_grayC7Color }]];
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
