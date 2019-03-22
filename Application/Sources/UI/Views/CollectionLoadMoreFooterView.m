//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CollectionLoadMoreFooterView.h"

#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <Masonry/Masonry.h>

@implementation CollectionLoadMoreFooterView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIImageView *loadingImageView = [UIImageView play_loadingImageView48WithTintColor:UIColor.play_lightGrayColor];
    [self addSubview:loadingImageView];
    [loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    self.backgroundColor = UIColor.clearColor;
}

@end
