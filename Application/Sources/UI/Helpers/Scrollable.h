//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol for view controllers with 'scroll to the top' support.
 */
@protocol Scrollable <NSObject>

- (void)scrollToTopAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
