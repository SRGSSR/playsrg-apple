//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchSettingSwitchCell : UITableViewCell

- (void)setName:(NSString *)name reader:(BOOL (^)(void))reader writer:(void (^)(BOOL value))writer;

@end

NS_ASSUME_NONNULL_END
