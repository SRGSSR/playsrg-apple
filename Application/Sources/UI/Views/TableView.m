//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TableView.h"

@implementation TableView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    if (self = [super initWithFrame:frame style:style]) {
        TableViewConfigure(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        TableViewConfigure(self);
    }
    return self;
}

@end

void TableViewConfigure(UITableView *tableView)
{
    tableView.backgroundColor = UIColor.clearColor;
    tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Avoid unreliable content size calculations when row heights are specified (leads to glitches during scrolling or
    // reloads). We do not use automatic cell sizing, so this is best avoided by default. This was the old default behavior,
    // but newer versions of Xcode now enable automatic sizing by default.
    tableView.estimatedRowHeight = 0.f;
    tableView.estimatedSectionFooterHeight = 0.f;
    tableView.estimatedSectionHeaderHeight = 0.f;
}
