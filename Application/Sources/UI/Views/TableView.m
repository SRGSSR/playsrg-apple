//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TableView.h"

static void commonInit(TableView *self)
{
    self.backgroundColor = UIColor.clearColor;
    self.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // The default when instantiated in a xib or storyboard. Avoid unreliable content size calculations
    // when row heights are specified. We do not use automatic cell sizing, so this is best avoided by
    // default.
    self.estimatedRowHeight = 0.f;
    self.estimatedSectionFooterHeight = 0.f;
    self.estimatedSectionHeaderHeight = 0.f;
}

@implementation TableView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    if (self = [super initWithFrame:frame style:style]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        commonInit(self);
    }
    return self;
}

@end
