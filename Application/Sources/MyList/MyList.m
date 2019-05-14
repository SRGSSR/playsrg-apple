//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MyList.h"

#import "Favorite+Private.h"
#import "PlayApplication.h"
#import "PushService.h"

#import <libextobjc/libextobjc.h>
#import <SRGUserData/SRGUserData.h>

static NSString * const MyListDomain = @"play";

#pragma mark Media metadata functions

BOOL MyListContainsShow(SRGShow *show)
{
    return [[SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:MyListDomain] ?: @[] containsObject:show.URN];
}

void MyListAddShow(SRGShow *show)
{
    NSInteger index = [[SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:MyListDomain] ?: @[] indexOfObject:show.URN];
    if (index == NSNotFound) {
        NSMutableArray<NSString *> *URNs = [SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:MyListDomain].mutableCopy ?: NSMutableArray.new;
        [URNs insertObject:show.URN atIndex:0];
        [SRGUserData.currentUserData.preferences setArray:URNs.copy atPath:@"myList" inDomain:MyListDomain];
    }
}

void MyListRemoveShows(NSArray<SRGShow *> *shows)
{
    if (shows) {
        NSMutableArray<NSString *> *URNs = [SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:MyListDomain].mutableCopy ?: NSMutableArray.new;
        NSArray<NSString *> *removeURNs = [shows valueForKeyPath:@"@distinctUnionOfObjects.URN"];
        [URNs removeObjectsInArray:removeURNs];
        [SRGUserData.currentUserData.preferences setArray:URNs.copy atPath:@"myList" inDomain:MyListDomain];
    }
    else {
       [SRGUserData.currentUserData.preferences setArray:@[] atPath:@"myList" inDomain:MyListDomain];
    }
}

BOOL MyListToggleShow(SRGShow *show)
{
    BOOL contained = MyListContainsShow(show);
    if (contained) {
        MyListRemoveShows(@[show]);
        return NO;
    }
    else {
        MyListAddShow(show);
        return YES;
    }
}

NSArray<NSString *> * MyListShowURNs()
{
    return [SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:MyListDomain] ?: @[];
}

void MyListMigrate(void)
{
    NSArray<Favorite *> *favorites = [Favorite showFavorites];
    if (favorites.count) {
        NSMutableArray<NSString *> *URNs = [SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:MyListDomain].mutableCopy ?: NSMutableArray.new;
        for (Favorite *favorite in favorites) {
            if (favorite.showURN && ! [URNs containsObject:favorite.showURN]) {
                [URNs insertObject:favorite.showURN atIndex:0];
            }
        }
        [SRGUserData.currentUserData.preferences setArray:URNs.copy atPath:@"myList" inDomain:MyListDomain];
        [Favorite finishMigrationForFavorites:favorites];
    }
    
    // Processes run once in the lifetime of the application
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        NSArray<NSString *> *subscribedShowURNs = PushService.sharedService.subscribedShowURNs;
        
        for (NSString *URN in subscribedShowURNs) {
            NSInteger index = [[SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:MyListDomain] ?: @[] indexOfObject:URN];
            if (index == NSNotFound) {
                NSMutableArray<NSString *> *URNs = [SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:MyListDomain].mutableCopy ?: NSMutableArray.new;
                [URNs insertObject:URN atIndex:0];
                [SRGUserData.currentUserData.preferences setArray:URNs.copy atPath:@"myList" inDomain:MyListDomain];
            }
        }
        completionHandler(subscribedShowURNs != nil);
    }, @"SubscriptionsToMyListMigrationDone", nil);
}
