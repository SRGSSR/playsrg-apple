//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MyList.h"

#import "Favorite+Private.h"

#import <libextobjc/libextobjc.h>
#import <SRGUserData/SRGUserData.h>

static NSString * const MyListDomain = @"play";

#pragma mark Media metadata functions

BOOL MyListContainsShow(SRGShow *show)
{
    return [[SRGUserData.currentUserData.preferences arrayForKeyPath:@"myList" inDomain:MyListDomain] ?: @[] containsObject:show.URN];
}

void MyListAddShow(SRGShow *show)
{
    NSInteger index = [[SRGUserData.currentUserData.preferences arrayForKeyPath:@"myList" inDomain:MyListDomain] ?: @[] indexOfObject:show.URN];
    if (index == NSNotFound) {
        NSMutableArray<NSString *> *URNs = [SRGUserData.currentUserData.preferences arrayForKeyPath:@"myList" inDomain:MyListDomain].mutableCopy ?: NSMutableArray.new;
        [URNs insertObject:show.URN atIndex:0];
        [SRGUserData.currentUserData.preferences setArray:URNs.copy forKeyPath:@"myList" inDomain:MyListDomain];
    }
}

void MyListRemoveShows(NSArray<SRGShow *> *shows)
{
    if (shows) {
        NSMutableArray<NSString *> *URNs = [SRGUserData.currentUserData.preferences arrayForKeyPath:@"myList" inDomain:MyListDomain].mutableCopy ?: NSMutableArray.new;
        NSArray<NSString *> *removeURNs = [shows valueForKeyPath:@"@distinctUnionOfObjects.URN"];
        [URNs removeObjectsInArray:removeURNs];
        [SRGUserData.currentUserData.preferences setArray:URNs.copy forKeyPath:@"myList" inDomain:MyListDomain];
    }
    else {
       [SRGUserData.currentUserData.preferences setArray:@[] forKeyPath:@"myList" inDomain:MyListDomain];
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
    return [SRGUserData.currentUserData.preferences arrayForKeyPath:@"myList" inDomain:MyListDomain] ?: @[];
}

void MyListMigrate(void)
{
}
