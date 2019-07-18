//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

NS_ASSUME_NONNULL_BEGIN

@interface PreviewingDelegate : NSObject <PreviewingDelegate>

- (instancetype)initWithRealDelegate:(id<PreviewingDelegate>)realDelegate;

@end

NS_ASSUME_NONNULL_END
