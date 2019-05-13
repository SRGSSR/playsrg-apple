//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

#import <MGSwipeTableCell/MGSwipeTableCell.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MyListTableViewCell;

@protocol MyListTableViewCellDelegate <NSObject>

- (void)myListTableViewCell:(MyListTableViewCell *)myListTableViewCell deleteShow:(SRGShow *)show;

@end

@interface MyListTableViewCell : MGSwipeTableCell <Previewing>

@property (nonatomic, nullable) SRGShow *show;
@property (nonatomic, weak) id<MyListTableViewCellDelegate> cellDelegate;

@end

NS_ASSUME_NONNULL_END
