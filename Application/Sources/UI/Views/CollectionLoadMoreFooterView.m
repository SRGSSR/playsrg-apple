//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CollectionLoadMoreFooterView.h"

#import "UIImageView+PlaySRG.h"

@import SRGAppearance;

@implementation CollectionLoadMoreFooterView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    
    UIImageView *loadingImageView = [UIImageView play_loadingImageView48WithTintColor:UIColor.srg_gray5Color];
    loadingImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:loadingImageView];
    
    [NSLayoutConstraint activateConstraints:@[
        [loadingImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [loadingImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    ]];
}

@end
