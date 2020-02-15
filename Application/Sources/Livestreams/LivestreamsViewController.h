//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeSectionInfo.h"
#import "PageViewController.h"
#import "PlayApplicationNavigation.h"

NS_ASSUME_NONNULL_BEGIN

@interface LivestreamsViewController : PageViewController <PlayApplicationNavigation>

- (instancetype)initWithHomeSections:(NSArray<NSNumber *> *)homeSections;

@end

@interface LivestreamsViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
