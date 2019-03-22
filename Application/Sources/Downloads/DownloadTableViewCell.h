//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Download.h"
#import "Previewing.h"

#import <MGSwipeTableCell/MGSwipeTableCell.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadTableViewCell : MGSwipeTableCell <Previewing>

@property (nonatomic, nullable) Download *download;

@end

NS_ASSUME_NONNULL_END
