//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TableLoadMoreFooterView.h"

#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <Masonry/Masonry.h>

@implementation TableLoadMoreFooterView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        UIImageView *loadingImageView = [UIImageView play_loadingImageView48WithTintColor:UIColor.play_lightGrayColor];
        [self addSubview:loadingImageView];
        [loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
        
        self.backgroundColor = UIColor.clearColor;
    }
    return self;
}

@end
