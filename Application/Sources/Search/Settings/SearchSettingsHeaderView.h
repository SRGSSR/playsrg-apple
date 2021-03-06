//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface SearchSettingsHeaderView : UITableViewHeaderFooterView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, getter=isSeparatorHidden) BOOL separatorHidden;         // Default is NO

@end

NS_ASSUME_NONNULL_END
