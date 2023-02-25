//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSectionInfo.h"

#import "ApplicationConfiguration.h"
#if TARGET_OS_IOS
#import "PushService.h"
#endif

ApplicationSectionOptionKey const ApplicationSectionOptionNotificationKey = @"ApplicationSectionOptionNotification";
ApplicationSectionOptionKey const ApplicationSectionOptionSearchMediaTypeOptionKey = @"ApplicationSectionOptionSearchMediaTypeOption";
ApplicationSectionOptionKey const ApplicationSectionOptionSearchQueryKey = @"ApplicationSectionOptionSearchQuery";
ApplicationSectionOptionKey const ApplicationSectionOptionShowAZIndexKey = @"ApplicationSectionOptionShowAZIndex";
ApplicationSectionOptionKey const ApplicationSectionOptionShowByDateDateKey = @"ApplicationSectionOptionShowByDateDate";

@interface ApplicationSectionInfo ()

@property (nonatomic) ApplicationSection applicationSection;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *uid;

@property (nonatomic) NSDictionary<ApplicationSectionOptionKey, id> *options;

@end

@implementation ApplicationSectionInfo

#pragma mark Class methods

+ (ApplicationSectionInfo *)applicationSectionInfoWithApplicationSection:(ApplicationSection)applicationSection radioChannel:(RadioChannel *)radioChannel
{
    return [self applicationSectionInfoWithApplicationSection:applicationSection radioChannel:radioChannel options:nil];
}

+ (ApplicationSectionInfo *)applicationSectionInfoWithApplicationSection:(ApplicationSection)applicationSection radioChannel:(RadioChannel *)radioChannel options:(NSDictionary<ApplicationSectionOptionKey, id> *)options
{
    return [[ApplicationSectionInfo alloc] initWithApplicationSection:applicationSection
                                                                title:TitleForApplicationSection(applicationSection)
                                                                  uid:radioChannel.uid
                                                              options:options];
}

#if TARGET_OS_IOS
+ (ApplicationSectionInfo *)applicationSectionInfoWithNotification:(UserNotification *)notification
{
    return [[ApplicationSectionInfo alloc] initWithApplicationSection:ApplicationSectionNotifications
                                                                title:notification.title
                                                                  uid:notification.identifier
                                                              options:@{ ApplicationSectionOptionNotificationKey : notification }];
}
#endif

+ (NSArray<ApplicationSectionInfo *> *)profileApplicationSectionInfosWithNotificationPreview:(BOOL)notificationPreview
{
    NSMutableArray<ApplicationSectionInfo *> *sectionInfos = [NSMutableArray array];
#if TARGET_OS_IOS
    if (PushService.sharedService.enabled) {
        [sectionInfos addObject:[self applicationSectionInfoWithApplicationSection:ApplicationSectionNotifications radioChannel:nil]];
        
        if (notificationPreview) {
            NSArray<UserNotification *> *unreadNotifications = UserNotification.unreadNotifications;
            NSArray<UserNotification *> *previewNotifications = [unreadNotifications subarrayWithRange:NSMakeRange(0, MIN(3, unreadNotifications.count))];
            for (UserNotification *notification in previewNotifications) {
                [sectionInfos addObject:[self applicationSectionInfoWithNotification:notification]];
            }
        }
    }
#endif
    [sectionInfos addObject:[self applicationSectionInfoWithApplicationSection:ApplicationSectionHistory radioChannel:nil]];
    [sectionInfos addObject:[self applicationSectionInfoWithApplicationSection:ApplicationSectionFavorites radioChannel:nil]];
    [sectionInfos addObject:[self applicationSectionInfoWithApplicationSection:ApplicationSectionWatchLater radioChannel:nil]];
#if TARGET_OS_IOS
    [sectionInfos addObject:[self applicationSectionInfoWithApplicationSection:ApplicationSectionDownloads radioChannel:nil]];
#endif
    
    return sectionInfos.copy;
}

#pragma Object lifecycle

- (instancetype)initWithApplicationSection:(ApplicationSection)applicationSection title:(NSString *)title uid:(NSString *)uid options:(NSDictionary<ApplicationSectionOptionKey, id> *)options
{
    if (self = [super init]) {
        self.applicationSection = applicationSection;
        self.title = title;
        self.uid = uid;
        self.options = options;
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithApplicationSection:ApplicationSectionUnknown title:@"" uid:nil options:nil];
}

#pragma clang diagnostic pop

#pragma mark Getters and setters

- (UIImage *)image
{
    switch (self.applicationSection) {
        case ApplicationSectionSearch: {
            return [UIImage imageNamed:@"search"];
            break;
        }
            
        case ApplicationSectionFavorites: {
            return [UIImage imageNamed:@"favorite"];
            break;
        }
            
        case ApplicationSectionWatchLater: {
            return [UIImage imageNamed:@"watch_later"];
            break;
        }
            
        case ApplicationSectionDownloads: {
            return [UIImage imageNamed:@"download"];
            break;
        }
            
        case ApplicationSectionHistory: {
            return [UIImage imageNamed:@"history"];
            break;
        }
            
        case ApplicationSectionNotifications: {
            return [UIImage imageNamed:@"subscription"];
            break;
        }
            
        default: {
            return nil;
            break;
        }
    }
}

- (RadioChannel *)radioChannel
{
    return [ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:self.uid];
}

#pragma mark Equality

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:self.class]) {
        return NO;
    }
    
    ApplicationSectionInfo *otherApplicationSectionInfo = object;
    return self.applicationSection == otherApplicationSectionInfo.applicationSection && (self.uid == otherApplicationSectionInfo.uid || [self.uid isEqual:otherApplicationSectionInfo.uid]);
}

- (NSUInteger)hash
{
    return [NSString stringWithFormat:@"%@_%@", @(self.applicationSection), self.uid].hash;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; applicationSection = %@, title = %@, uid = %@>",
            self.class,
            self,
            @(self.applicationSection),
            self.title,
            self.uid];
}

@end
