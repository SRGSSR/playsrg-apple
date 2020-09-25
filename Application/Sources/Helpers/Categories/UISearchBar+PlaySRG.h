//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UISearchBar (PlaySRG)

/**
 *  Text field contained in a search bar.
 */
@property (nonatomic, readonly) UITextField *play_textField;

/**
 *  Bookmark button contained in a search bar, if any.
 */
@property (nonatomic, readonly, nullable) UIButton *play_bookmarkButton;

@end

NS_ASSUME_NONNULL_END
