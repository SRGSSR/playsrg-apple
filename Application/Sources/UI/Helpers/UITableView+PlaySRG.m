//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UITableView+PlaySRG.h"

@implementation UITableView (PlaySRG)

- (void)play_scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    @try {
        [self scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
    }
    @catch (NSException *exception) {}
}

@end
