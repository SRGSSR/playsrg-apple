//
//  UITableView+PlaySRG.h
//  PlaySRG
//
//  Created by Samuel Défago on 16.09.21.
//  Copyright © 2021 SRG SSR. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableView (PlaySRG)

/**
 *  Same as `-scrollToRowAtIndexPath:atScrollPosition:animated:` but inhibiting assertions.
 */
- (void)play_scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
