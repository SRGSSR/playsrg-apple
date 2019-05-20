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

NSString * const PlayPreferenceDomain = @"play";

static NSString * const PlayMyListPath = @"myList";
static NSString * const PlayDatePath = @"date";
static NSString * const PlayNotificationsPath = @"notifications";
static NSString * const PlayNewOnDemandPath = @"newod";

static NSString * const SubscriptionsToMyListMigrationDoneKey = @"SubscriptionsToMyListMigrationDone";

#pragma mark Private

BOOL MyListContainsShowURN(NSString *URN)
{
    NSString *path = [PlayMyListPath stringByAppendingPathComponent:URN];
    return [SRGUserData.currentUserData.preferences hasObjectAtPath:path inDomain:PlayPreferenceDomain];
}

void MyListAddShowURNWithDate(NSString *URN, NSDate *date)
{
    if (! MyListContainsShowURN(URN)) {
        NSString *path = [[PlayMyListPath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:PlayDatePath];
        [SRGUserData.currentUserData.preferences setNumber:@(round(date.timeIntervalSince1970 * 1000.)) atPath:path inDomain:PlayPreferenceDomain];
    }
}

BOOL MyListIsSubscribedToShowURN(NSString * _Nonnull URN)
{
    if (! MyListContainsShowURN(URN)) {
        return NO;
    }
    
    if (! PushService.sharedService.enabled) {
        return NO;
    }
    
    NSString *path = [[[PlayMyListPath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:PlayNotificationsPath] stringByAppendingPathComponent:PlayNewOnDemandPath];
    return [SRGUserData.currentUserData.preferences numberAtPath:path inDomain:PlayPreferenceDomain].boolValue;
}

// Force subscription, even if Push Notifications are disabled.
void MyListSubscribeToShowURN(NSString *URN)
{
    if (MyListContainsShowURN(URN) && ! MyListIsSubscribedToShowURN(URN)) {
        NSString *path = [[[PlayMyListPath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:PlayNotificationsPath] stringByAppendingPathComponent:PlayNewOnDemandPath];
        [SRGUserData.currentUserData.preferences setNumber:@YES atPath:path inDomain:PlayPreferenceDomain];
    }
}

#pragma mark Push service synchronization

void MyListUpdatePushService(void)
{
    if ([PlayApplicationRunOnceObjectForKey(SubscriptionsToMyListMigrationDoneKey) boolValue]) {
        NSMutableSet<NSString *> *subscribedURNs = [NSMutableSet set];
        for (NSString *URN in MyListShowURNs()) {
            if (MyListIsSubscribedToShowURN(URN)) {
                [subscribedURNs addObject:URN];
            }
        }
        NSSet<NSString *> *subscribedMyListURNs = subscribedURNs.copy;
        NSSet<NSString *> *subscribedPushServiceURNs = PushService.sharedService.subscribedShowURNs;
        
        if (! [subscribedMyListURNs isEqualToSet:subscribedPushServiceURNs]) {
            NSPredicate *toAddPredicate = [NSPredicate predicateWithFormat:@"! SELF IN %@", subscribedPushServiceURNs];
            NSSet<NSString *> *toAddURNs = [subscribedMyListURNs filteredSetUsingPredicate:toAddPredicate];
            if (toAddURNs.count > 0) {
                [PushService.sharedService subscribeToShowURNs:toAddURNs];
            }
            
            NSPredicate *toRemovePredicate = [NSPredicate predicateWithFormat:@"! SELF IN %@", subscribedMyListURNs];
            NSSet<NSString *> *toRemoveURNs = [subscribedPushServiceURNs filteredSetUsingPredicate:toRemovePredicate];
            if (toRemoveURNs.count > 0) {
                [PushService.sharedService unsubscribeFromShowURNs:toRemoveURNs];
            }
        }
        
        NSCAssert([subscribedMyListURNs isEqualToSet:PushService.sharedService.subscribedShowURNs], @"Subscribed My List shows have to be equal to Push Service subscribed shows");
    }
}

void MyListSetup(void)
{
    MyListUpdatePushService();
    
    [NSNotificationCenter.defaultCenter addObserverForName:SRGPreferencesDidChangeNotification object:SRGUserData.currentUserData.preferences queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSSet<NSString *> *domains = notification.userInfo[SRGPreferencesDomainsKey];
        if ([domains containsObject:PlayPreferenceDomain]) {
            MyListUpdatePushService();
        }
    }];
}

#pragma mark My List entries

BOOL MyListContainsShow(SRGShow *show)
{
    return MyListContainsShowURN(show.URN);
}

void MyListAddShow(SRGShow *show)
{
    MyListAddShowURNWithDate(show.URN, NSDate.date);
}

void MyListRemoveShows(NSArray<SRGShow *> *shows)
{
    NSArray<NSString *> *URNs = nil;
    if (shows) {
        NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(SRGShow.new, URN)];
        URNs = [shows valueForKeyPath:keyPath];
    }
    else {
        URNs = MyListShowURNs().allObjects;
    }
    
    NSMutableArray<NSString *> *paths = NSMutableArray.array;
    for (NSString *URN in URNs) {
        [paths addObject:[PlayMyListPath stringByAppendingPathComponent:URN]];
    }
    [SRGUserData.currentUserData.preferences removeObjectsAtPaths:paths.copy inDomain:PlayPreferenceDomain];
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
    NSArray<NSString *> *URNs = [SRGUserData.currentUserData.preferences dictionaryAtPath:PlayMyListPath inDomain:PlayPreferenceDomain].allKeys;
    return (URNs) ? [NSSet setWithArray:URNs] : [NSSet set];
}

#pragma mark Subscriptions

BOOL MyListToggleSubscriptionForShow(SRGShow *show, UIView *view)
{
    if (! MyListContainsShow(show)) {
        return NO;
    }
    
    BOOL toggled = NO;
    if (view) {
        toggled = [PushService.sharedService toggleSubscriptionForShow:show inView:view];
    }
    else {
        toggled = [PushService.sharedService toggleSubscriptionForShow:show];
    }
    
    if (! toggled) {
        return NO;
    }
    
    BOOL subscribed = [PushService.sharedService isSubscribedToShowURN:show.URN];
    NSString *path = [[[PlayMyListPath stringByAppendingPathComponent:show.URN] stringByAppendingPathComponent:PlayNotificationsPath] stringByAppendingPathComponent:PlayNewOnDemandPath];
    [SRGUserData.currentUserData.preferences setNumber:@(subscribed) atPath:path inDomain:PlayPreferenceDomain];
    
    return YES;
}

BOOL MyListIsSubscribedToShow(SRGShow * _Nonnull show)
{
    return MyListIsSubscribedToShowURN(show.URN);
}

#pragma mark Migration

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
            MyListSubscribeToShowURN(URN);
        }
        completionHandler(subscribedShowURNs != nil);
    }, SubscriptionsToMyListMigrationDoneKey, nil);
}
