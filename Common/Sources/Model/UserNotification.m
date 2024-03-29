//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UserNotification.h"

#import "NSFileManager+PlaySRG.h"
#import "PlayLogger.h"

@import libextobjc;

NSString * const UserNotificationsDidChangeNotification = @"UserNotificationsDidChangeNotification";

static NSValueTransformer *NotificationTypeTransformer(void);

static NSString *NotificationDescriptionForType(UserNotificationType notificationType)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_descriptions;
    dispatch_once(&s_onceToken, ^{
        s_descriptions = @{ @(UserNotificationTypeNewOnDemandContentAvailable) : @"New on-demand content available" };
    });
    return s_descriptions[@(notificationType)];
}

@interface UserNotification ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;
@property (nonatomic) NSURL *imageURL;
@property (nonatomic) NSDate *date;
@property (nonatomic, getter=isRead) BOOL read;
@property (nonatomic) UserNotificationType type;
@property (nonatomic, copy) NSString *mediaURN;
@property (nonatomic, copy) NSString *showURN;
@property (nonatomic, copy) NSString *channelUid;

@end

@implementation UserNotification

#pragma mark Class methods

+ (NSArray<UserNotification *> *)notifications
{
    NSMutableArray<UserNotification *> *notificationsArray = [NSMutableArray array];
    NSArray *notificationsPlistArray = [NSArray arrayWithContentsOfURL:[self notificationsFilePath]];
    [notificationsPlistArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            NSDictionary *notificationDictionary = (NSDictionary *)obj;
            UserNotification *notification = [[UserNotification alloc] initWithDictionary:notificationDictionary];
            if (notification) {
                [notificationsArray addObject:notification];
            }
            else {
                PlayLogError(@"notifications", @"A notification could not be loaded and was skipped.");
            }
        }
    }];
    
    NSDate *currentDate = NSDate.date;
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:-14];
    NSDate *fourteenDaysAgo = [NSCalendar.srg_defaultCalendar dateByAddingComponents:dateComponents toDate:currentDate options:0];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@", @keypath(UserNotification.new, date), fourteenDaysAgo];
    return [notificationsArray filteredArrayUsingPredicate:predicate];
}

+ (NSArray<UserNotification *> *)unreadNotifications
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(UserNotification.new, read), @NO];
    return [UserNotification.notifications filteredArrayUsingPredicate:predicate];
}

+ (void)saveNotification:(UserNotification *)notification read:(BOOL)read
{
    NSArray<UserNotification *> *notifications = [self notifications];
    
    NSInteger index = [notifications indexOfObject:notification];
    if (index != NSNotFound) {
        // Flag a notification unread again is not allowed.
        UserNotification *originalNotification = notifications[index];
        if (read && ! originalNotification.read) {
            notification.read = YES;
        }
        NSMutableArray<UserNotification *> *updatedNotifications = notifications.mutableCopy;
        [updatedNotifications replaceObjectAtIndex:index withObject:notification];
        notifications = updatedNotifications.copy;
    }
    else {
        notifications = [notifications arrayByAddingObject:notification];
    }
    
    NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(UserNotification.new, date) ascending:NO];
    NSSortDescriptor *identifierSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(UserNotification.new, identifier) ascending:NO];
    notifications = [notifications sortedArrayUsingDescriptors:@[dateSortDescriptor, identifierSortDescriptor]];
    [self saveNotifications:notifications];
}

+ (NSURL *)notificationsFilePath
{
    return [[NSFileManager.play_applicationGroupContainerURL URLByAppendingPathComponent:@"Library"] URLByAppendingPathComponent:@"notifications.plist"];
}

+ (void)saveNotifications:(NSArray<UserNotification *> *)notifications
{
    NSMutableArray<NSDictionary *> *notificationsArray = [NSMutableArray array];
    [notifications enumerateObjectsUsingBlock:^(UserNotification * _Nonnull notification, NSUInteger idx, BOOL * _Nonnull stop) {
        [notificationsArray addObject:notification.dictionary];
    }];
    
    NSError *plistError = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:notificationsArray
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:&plistError];
    if (plistError) {
        PlayLogError(@"notifications", @"Could not save notifications data. Reason: %@", plistError);
        return;
    }
    
    NSError *writeError = nil;
    [plistData writeToURL:[self notificationsFilePath] options:NSDataWritingAtomic error:&writeError];
    if (writeError) {
        PlayLogError(@"notifications", @"Could not save notifications data. Reason: %@", writeError);
    }
    else {
        [NSNotificationCenter.defaultCenter postNotificationName:UserNotificationsDidChangeNotification object:nil];
    }
}

#pragma mark Object lifecycle

- (instancetype)initWithRequest:(UNNotificationRequest *)notificationRequest
{
    return [self initWithRequest:notificationRequest date:NSDate.date];
}

- (instancetype)initWithNotification:(UNNotification *)notification
{
    return [self initWithRequest:notification.request date:notification.date];
}

- (instancetype)initWithRequest:(UNNotificationRequest *)notificationRequest date:(NSDate *)date
{
    if (self = [super init]) {
        self.identifier = notificationRequest.identifier;
        self.date = date;
        
        self.title = notificationRequest.content.title ?: @"";
        self.body = notificationRequest.content.body;
        
        NSDictionary *userInfo = notificationRequest.content.userInfo;
        self.type = UserNotificationTypeFromString(userInfo[@"type"]);
        self.imageURL = userInfo[@"imageUrl"] ? [NSURL URLWithString:userInfo[@"imageUrl"]] : nil;
        self.mediaURN = userInfo[@"media"];
        self.showURN = userInfo[@"show"];
        self.channelUid = userInfo[@"channelId"];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.identifier = dictionary[@"identifier"];
        self.date = dictionary[@"date"];
        self.read = [dictionary[@"read"] boolValue];
        
        self.title = dictionary[@"title"];
        self.body = dictionary[@"body"];
        
        self.type = UserNotificationTypeFromString(dictionary[@"type"]);
        self.imageURL = dictionary[@"imageUrl"] ? [NSURL URLWithString:dictionary[@"imageUrl"]] : nil;
        self.mediaURN = dictionary[@"media"];
        self.showURN = dictionary[@"show"];
        self.channelUid = dictionary[@"channelId"];
    }
    return self;
}

#pragma mark Getters and setters

- (NSDictionary *)dictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"identifier"] = self.identifier;
    dictionary[@"date"] = self.date;
    dictionary[@"read"] = @(self.read);
    
    dictionary[@"title"] = self.title;
    dictionary[@"body"] = self.body;
    
    dictionary[@"imageUrl"] = self.imageURL.absoluteString;
    dictionary[@"type"] = UserNotificationTypeString(self.type);
    dictionary[@"media"] = self.mediaURN;
    dictionary[@"show"] = self.showURN;
    dictionary[@"channelId"] = self.channelUid;
    return dictionary.copy;
}

- (SRGImage *)image
{
    return [SRGImage imageWithURL:self.imageURL variant:SRGImageVariantDefault];
}

#pragma mark MTLJSONSerializing protocol

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    static NSDictionary *s_mapping;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_mapping = @{
            @keypath(UserNotification.new, identifier) : @"identifier",
            @keypath(UserNotification.new, date) : @"date",
            @keypath(UserNotification.new, read) : @"read",
            
            @keypath(UserNotification.new, title) : @"title",
            @keypath(UserNotification.new, body) : @"body",
            
            @keypath(UserNotification.new, imageURL) : @"imageUrl",
            @keypath(UserNotification.new, type) : @"type",
            @keypath(UserNotification.new, mediaURN) : @"media",
            @keypath(UserNotification.new, showURN) : @"show",
            @keypath(UserNotification.new, channelUid) : @"channelId"
        };
    });
    return s_mapping;
}

#pragma mark Transformers

+ (NSValueTransformer *)dateJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^(NSNumber *number, BOOL *success, NSError **pError) {
        return [NSDate dateWithTimeIntervalSince1970:number.floatValue];
    } reverseBlock:^(NSDate *date, BOOL *success, NSError **pError) {
        return [NSNumber numberWithDouble:date.timeIntervalSince1970];
    }];
}

+ (NSValueTransformer *)imageURLJSONTransformer
{
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)typeJSONTransformer
{
    return NotificationTypeTransformer();
}

#pragma mark Equality

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:self.class]) {
        return NO;
    }
    
    UserNotification *otherNotification = object;
    return [self.identifier isEqualToString:otherNotification.identifier];
}

- (NSUInteger)hash
{
    return self.identifier.hash;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; identifier = %@; title = %@; date = %@; type: %@, read: %@>",
            self.class,
            self,
            self.identifier,
            self.title,
            self.date,
            NotificationDescriptionForType(self.type),
            self.read ? @"YES" : @"NO"];
}

@end

#pragma mark NotificationType transformations

static NSValueTransformer *NotificationTypeTransformer(void)
{
    static NSValueTransformer *s_transformer;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{ @"newod" : @(UserNotificationTypeNewOnDemandContentAvailable) }
                                                                         defaultValue:@(UserNotificationTypeNone)
                                                                  reverseDefaultValue:nil];
    });
    return s_transformer;
}

UserNotificationType UserNotificationTypeFromString(NSString *notificationType)
{
    return [[NotificationTypeTransformer() transformedValue:notificationType] integerValue];
}

NSString * UserNotificationTypeString(UserNotificationType notificationType)
{
    return [NotificationTypeTransformer() reverseTransformedValue:@(notificationType)];
}
