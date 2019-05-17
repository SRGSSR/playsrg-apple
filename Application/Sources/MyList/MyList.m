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

#pragma mark Private

BOOL MyListContainsShowURN(NSString *URN)
{
    NSString *path = [PlayMyListPath stringByAppendingPathComponent:URN];
    return [SRGUserData.currentUserData.preferences hasObjectAtPath:path inDomain:PlayPreferenceDomain];
}

void MyListAddShowURNWithDate(NSString *URN, NSDate *date)
{
    if (! MyListContainsShowURN(URN)) {
        NSString *path = [PlayMyListPath stringByAppendingPathComponent:URN];
        NSDictionary *myListEntry = @{ PlayDatePath : @(round(date.timeIntervalSince1970 * 1000.)),
                                       PlayNotificationsPath : @{ PlayNewOnDemandPath : @NO } };
        [SRGUserData.currentUserData.preferences setDictionary:myListEntry atPath:path inDomain:PlayPreferenceDomain];
    }
}

OBJC_EXPORT BOOL MyListIsSubscribedToShowURN(NSString * _Nonnull URN)
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


void MyListSubscribedToShowURN(NSString *URN)
{
    if (MyListContainsShowURN(URN) && ! MyListIsSubscribedToShowURN(URN)) {
        [PushService.sharedService subscribeToShowURN:URN];
        NSString *path = [[[PlayMyListPath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:PlayNotificationsPath] stringByAppendingPathComponent:PlayNewOnDemandPath];
        [SRGUserData.currentUserData.preferences setNumber:@YES atPath:path inDomain:PlayPreferenceDomain];
    }
}

void MyListUnsubscribedFromShowURN(NSString *URN)
{
    if (MyListContainsShowURN(URN) && MyListIsSubscribedToShowURN(URN)) {
        [PushService.sharedService unsubscribeFromShowURNs:[NSSet setWithObject:URN]];
        NSString *path = [[[PlayMyListPath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:PlayNotificationsPath] stringByAppendingPathComponent:PlayNewOnDemandPath];
        [SRGUserData.currentUserData.preferences setNumber:@NO atPath:path inDomain:PlayPreferenceDomain];
    }
}

void MyListSubscribedToShow(SRGShow *show)
{
    MyListSubscribedToShowURN(show.URN);
}

void MyListUnsubscribedFromShow(SRGShow *show)
{
    MyListUnsubscribedFromShowURN(show.URN);
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
    if (shows) {
        NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(SRGShow.new, URN)];
        [PushService.sharedService unsubscribeFromShowURNs:[shows valueForKeyPath:keyPath]];
        
        for (SRGShow *show in shows) {
            NSString *path = [PlayMyListPath stringByAppendingPathComponent:show.URN];
            [SRGUserData.currentUserData.preferences removeObjectAtPath:path inDomain:PlayPreferenceDomain];
        }
    }
    else {
        [PushService.sharedService unsubscribeFromShowURNs:PushService.sharedService.subscribedShowURNs];
        
        [SRGUserData.currentUserData.preferences setDictionary:@{} atPath:PlayMyListPath inDomain:PlayPreferenceDomain];
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
    return [NSSet setWithArray:[SRGUserData.currentUserData.preferences dictionaryAtPath:PlayMyListPath inDomain:PlayPreferenceDomain].allKeys];
}

#pragma mark Subscriptions

BOOL MyListToggleSubscriptionShow(SRGShow *show, UIView *view)
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

OBJC_EXPORT BOOL MyListIsSubscribedToShow(SRGShow * _Nonnull show)
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
            MyListSubscribedToShowURN(URN);
        }
        completionHandler(subscribedShowURNs != nil);
    }, @"SubscriptionsToMyListMigrationDone", nil);
}
