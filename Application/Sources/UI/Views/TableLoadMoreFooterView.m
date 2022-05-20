//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TableLoadMoreFooterView.h"

#import "UIImageView+PlaySRG.h"

@import SRGAppearance;

@implementation TableLoadMoreFooterView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
        
        UIImageView *loadingImageView = [UIImageView play_loadingImageViewWithTintColor:UIColor.srg_grayC7Color];
        [self addSubview:loadingImageView];
        
        loadingImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [loadingImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [loadingImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
    }
    return self;
}

@end
