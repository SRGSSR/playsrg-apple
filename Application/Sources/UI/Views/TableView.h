//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Apply standard Play configuration to a given table view (with manual cell height).
 */
OBJC_EXPORT void TableViewConfigure(UITableView *tableView);

/**
 *  Properly configured Play standard table view for instantiation in code (with manual cell height).
 */
@interface TableView : UITableView

@end

NS_ASSUME_NONNULL_END
