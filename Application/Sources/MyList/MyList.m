//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MyList.h"

#import "Favorite+Private.h"
#import "PlayApplication.h"
#import "PushService+Private.h"

#import <libextobjc/libextobjc.h>
#import <SRGUserData/SRGUserData.h>

static NSString * const PlayPreferenceDomain = @"play";

static NSString * const MyListPreferencePath = @"myList";
static NSString * const DatePreferencePath = @"date";
static NSString * const NotificationsPreferencePath = @"notifications";
static NSString * const NewOnDemandNotificationPreferencePath = @"newod";

#pragma mark Media metadata functions

BOOL MyListContainsShowURN(NSString *URN)
{
    NSString *path = [MyListPreferencePath stringByAppendingPathComponent:URN];
    return [SRGUserData.currentUserData.preferences hasObjectAtPath:path inDomain:PlayPreferenceDomain];
}

BOOL MyListContainsShow(SRGShow *show)
{
    return MyListContainsShowURN(show.URN);
}

void MyListAddShowURNWithDate(NSString *URN, NSDate *date)
{
    if (! MyListContainsShowURN(URN)) {
        NSString *path = [MyListPreferencePath stringByAppendingPathComponent:URN];
        NSDictionary *myListEntry = @{ DatePreferencePath : @(round(date.timeIntervalSince1970 * 1000.)),
                                       NotificationsPreferencePath : @{ NewOnDemandNotificationPreferencePath : @NO } };
        [SRGUserData.currentUserData.preferences setDictionary:myListEntry atPath:path inDomain:PlayPreferenceDomain];
    }
}

void MyListSubscribedToShowURN(NSString *URN)
{
    if (MyListContainsShowURN(URN)) {
        NSString *path = [[MyListPreferencePath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:NotificationsPreferencePath];
        NSMutableDictionary *notifications = [SRGUserData.currentUserData.preferences dictionaryAtPath:path inDomain:PlayPreferenceDomain].mutableCopy;
        notifications[NewOnDemandNotificationPreferencePath] = @YES;
        [SRGUserData.currentUserData.preferences setDictionary:notifications.copy atPath:path inDomain:PlayPreferenceDomain];
    }
}

void MyListSubscribedToShow(SRGShow *show)
{
    MyListSubscribedToShowURN(show.URN);
}

void MyListUnsubscribedFromShowURN(NSString *URN)
{
    if (MyListContainsShowURN(URN)) {
        NSString *path = [[MyListPreferencePath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:NotificationsPreferencePath];
        NSMutableDictionary *notifications = [SRGUserData.currentUserData.preferences dictionaryAtPath:path inDomain:PlayPreferenceDomain].mutableCopy;
        notifications[NewOnDemandNotificationPreferencePath] = @NO;
        [SRGUserData.currentUserData.preferences setDictionary:notifications.copy atPath:path inDomain:PlayPreferenceDomain];
    }
}

void MyListUnsubscribedFromShow(SRGShow *show)
{
    MyListUnsubscribedFromShowURN(show.URN);
}

void MyListAddShow(SRGShow *show)
{
    MyListAddShowURNWithDate(show.URN, NSDate.date);
}

void MyListRemoveShows(NSArray<SRGShow *> *shows)
{
    if (shows) {
        NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(SRGShow.new, URN)];
        [PushService.sharedService silenceUnsubscribtionFromShowURNs:[shows valueForKeyPath:keyPath]];
        
        for (SRGShow *show in shows) {
            NSString *path = [MyListPreferencePath stringByAppendingPathComponent:show.URN];
            [SRGUserData.currentUserData.preferences removeObjectAtPath:path inDomain:PlayPreferenceDomain];
        }
    }
    else {
        [PushService.sharedService silenceUnsubscribtionFromShowURNs:PushService.sharedService.subscribedShowURNs];
        
        [SRGUserData.currentUserData.preferences setDictionary:@{} atPath:MyListPreferencePath inDomain:PlayPreferenceDomain];
    }
}

BOOL MyListToggleShow(SRGShow *show)
{
    BOOL contained = MyListContainsShow(show);
    if (contained) {
        MyListRemoveShows(@[show]);
    }
    else {
        MyListAddShow(show);
    }
    
    return YES;
}

NSSet<NSString *> * MyListShowURNs()
{
    return [NSSet setWithArray:[SRGUserData.currentUserData.preferences dictionaryAtPath:MyListPreferencePath inDomain:PlayPreferenceDomain].allKeys];
}

BOOL MyListToggleSubscriptionShow(SRGShow *show, UIView *view, BOOL withBanner)
{
    if (! MyListContainsShow(show)) {
        return NO;
    }
    
    BOOL toggled = NO;
    if (withBanner) {
        toggled = [PushService.sharedService toggleSubscriptionForShow:show inView:view];
    }
    else {
        toggled = [PushService.sharedService toggleSubscriptionForShow:show];
    }
    if (! toggled) {
        return NO;
    }
    
    BOOL subscribed = [PushService.sharedService isSubscribedToShow:show];
    NSString *path = [[[MyListPreferencePath stringByAppendingPathComponent:show.URN] stringByAppendingPathComponent:NotificationsPreferencePath] stringByAppendingPathComponent:NewOnDemandNotificationPreferencePath];
    [SRGUserData.currentUserData.preferences setNumber:@(subscribed) atPath:path inDomain:PlayPreferenceDomain];
    
    return YES;
}

OBJC_EXPORT BOOL MyListIsSubscribedToShow(SRGShow * _Nonnull show)
{
    if (! MyListContainsShow(show)) {
        return NO;
    }
    
    if (! PushService.sharedService.enabled) {
        return NO;
    }
    
    NSString *path = [[[MyListPreferencePath stringByAppendingPathComponent:show.URN] stringByAppendingPathComponent:NotificationsPreferencePath] stringByAppendingPathComponent:NewOnDemandNotificationPreferencePath];
    return [SRGUserData.currentUserData.preferences numberAtPath:path inDomain:PlayPreferenceDomain].boolValue;
}

void MyListMigrate(void)
{
    NSArray<Favorite *> *favorites = [Favorite showFavorites];
    if (favorites.count) {
        for (Favorite *favorite in favorites) {
            if (favorite.showURN && ! MyListContainsShowURN(favorite.showURN)) {
                MyListAddShowURNWithDate(favorite.showURN, favorite.date ?: NSDate.date);
            }
        }
        [Favorite finishMigrationForFavorites:favorites];
    }
    
    // Processes run once in the lifetime of the application
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        NSSet<NSString *> *subscribedShowURNs = PushService.sharedService.subscribedShowURNs;
        
        for (NSString *URN in subscribedShowURNs) {
            if (! MyListContainsShowURN(URN)) {
                MyListAddShowURNWithDate(URN, NSDate.date);
            }
            MyListSubscribedToShowURN(URN);
        }
        completionHandler(subscribedShowURNs != nil);
    }, @"SubscriptionsToMyListMigrationDone", nil);
}
