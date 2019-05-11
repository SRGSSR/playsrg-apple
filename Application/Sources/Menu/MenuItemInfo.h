//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ApplicationConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * MenuItemOptionKey NS_STRING_ENUM;

OBJC_EXPORT MenuItemOptionKey const MenuItemOptionSearchOptionKey;                              // Key to access the search option key, as an `NSNUmber`.
OBJC_EXPORT MenuItemOptionKey const MenuItemOptionSearchQueryKey;                               // Key to access the search query key, as a `NSString`.

@interface MenuItemInfo : NSObject

+ (MenuItemInfo *)menuItemInfoWithMenuItem:(MenuItem)menuItem;
+ (MenuItemInfo *)menuItemInfoWithRadioChannel:(RadioChannel *)radioChannel;

+ (MenuItemInfo *)menuItemInfoWithMenuItem:(MenuItem)menuItem options:(nullable NSDictionary<NSString *, id> *)options;
+ (MenuItemInfo *)menuItemInfoWithRadioChannel:(RadioChannel *)radioChannel options:(nullable NSDictionary<NSString *, id> *)options;

- (instancetype)initWithMenuItem:(MenuItem)menuItem title:(NSString *)title uid:(nullable NSString *)uid options:(nullable NSDictionary<NSString *, id> *)options NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) MenuItem menuItem;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy, nullable) NSString *uid;

@property (nonatomic, readonly, nullable) UIImage *image;

@property (nonatomic, readonly, nullable) NSDictionary<MenuItemOptionKey, id> *options;

/**
 *  Returns a radio channel iff the menu item info is related to a radio channel, `nil` otherwise.
 */
@property (nonatomic, readonly, nullable) RadioChannel *radioChannel;

@end

@interface MenuItemInfo (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

