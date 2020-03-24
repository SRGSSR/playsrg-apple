//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchLoadingCollectionViewCell.h"

#import "NSBundle+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

@interface SearchLoadingCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation SearchLoadingCollectionViewCell

#pragma mark Overrides

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.imageView play_stopAnimating];
}

#pragma mark Animation

- (void)startAnimating
{
    [self.imageView play_startAnimatingLoading90WithTintColor:UIColor.play_lightGrayColor];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

@end
