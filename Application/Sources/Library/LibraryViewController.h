//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseViewController.h"
#import "ContentInsets.h"
#import "PlayApplicationNavigation.h"
#import "Scrollable.h"

#import <CoconutKit/CoconutKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LibraryViewController : BaseViewController <ContentInsets, PlayApplicationNavigation, Scrollable, UITableViewDataSource, UITableViewDelegate>

@end

NS_ASSUME_NONNULL_END
