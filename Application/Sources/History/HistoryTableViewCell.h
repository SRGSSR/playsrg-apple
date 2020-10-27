//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

#import <MGSwipeTableCell/MGSwipeTableCell.h>

@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class HistoryTableViewCell;

@protocol HistoryTableViewCellDelegate <NSObject>

- (void)historyTableViewCell:(HistoryTableViewCell *)historyTableViewCell deleteHistoryEntryForMedia:(SRGMedia *)media;

@end

@interface HistoryTableViewCell : MGSwipeTableCell <Previewing>

@property (nonatomic, nullable) SRGMedia *media;
@property (nonatomic, weak) id<HistoryTableViewCellDelegate> cellDelegate;

@end

NS_ASSUME_NONNULL_END
