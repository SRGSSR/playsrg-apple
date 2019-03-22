//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ApplicationConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface MenuItemInfo : NSObject

+ (MenuItemInfo *)menuItemInfoWithMenuItem:(MenuItem)menuItem;
+ (MenuItemInfo *)menuItemInfoWithRadioChannel:(RadioChannel *)radioChannel;

- (instancetype)initWithMenuItem:(MenuItem)menuItem title:(NSString *)title uid:(nullable NSString *)uid NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithMenuItem:(MenuItem)menuItem title:(NSString *)title;

@property (nonatomic, readonly) MenuItem menuItem;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy, nullable) NSString *uid;

@property (nonatomic, readonly, nullable) UIImage *image;

/**
 *  Returns a radio channel iff the menu item info is related to a radio channel, `nil` otherwise.
 */
@property (nonatomic, readonly, nullable) RadioChannel *radioChannel;

@end

@interface MenuItemInfo (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

