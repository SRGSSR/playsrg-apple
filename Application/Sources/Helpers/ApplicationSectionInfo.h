//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSection.h"
#import "RadioChannel.h"
#if TARGET_OS_IOS
#import "UserNotification.h"
#endif

@import Foundation;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

typedef NSString * ApplicationSectionOptionKey NS_STRING_ENUM;

OBJC_EXPORT ApplicationSectionOptionKey const ApplicationSectionOptionNotificationKey;                              // Key to access the notification key, as an `Notification`.
OBJC_EXPORT ApplicationSectionOptionKey const ApplicationSectionOptionSearchMediaTypeOptionKey;                     // Key to access the search media type option key, as an `NSNumber`.
OBJC_EXPORT ApplicationSectionOptionKey const ApplicationSectionOptionSearchQueryKey;                               // Key to access the search query key, as an `NSString`.
OBJC_EXPORT ApplicationSectionOptionKey const ApplicationSectionOptionShowAZIndexKey;                               // Key to access the A-Z index key, as an `NSString`.
OBJC_EXPORT ApplicationSectionOptionKey const ApplicationSectionOptionShowByDateDateKey;                            // Key to access the "show by date" date key, as an `NSDate`.

/**
 *  Section of the application, corresponding to some functionality.
 */
@interface ApplicationSectionInfo : NSObject

/**
 *  Standard sections.
 */
+ (ApplicationSectionInfo *)applicationSectionInfoWithApplicationSection:(ApplicationSection)applicationSection radioChannel:(nullable RadioChannel *)radioChannel;
+ (ApplicationSectionInfo *)applicationSectionInfoWithApplicationSection:(ApplicationSection)applicationSection radioChannel:(nullable RadioChannel *)radioChannel options:(nullable NSDictionary<ApplicationSectionOptionKey, id> *)options;

/**
 *  Return the profile section infos available for the current configuration.
 */
+ (NSArray<ApplicationSectionInfo *> *)profileApplicationSectionInfos;

/**
 *  Return the help section infos available for the current configuration.
 */
+ (NSArray<ApplicationSectionInfo *> *)helpApplicationSectionInfos;

/**
 *  Properties.
 */
@property (nonatomic, readonly) ApplicationSection applicationSection;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy, nullable) NSString *uid;
@property (nonatomic, readonly, nullable) UIImage *image;
@property (nonatomic, readonly, nullable) NSString *imageName;
@property (nonatomic, readonly, nullable) NSDictionary<ApplicationSectionOptionKey, id> *options;
@property (nonatomic, readonly, getter=isModalPresentation) BOOL modalPresentation;

@property (nonatomic, readonly, nullable) RadioChannel *radioChannel;

@end

@interface ApplicationSectionInfo (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
