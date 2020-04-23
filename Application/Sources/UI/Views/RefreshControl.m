//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RefreshControl.h"

@implementation RefreshControl

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.tintColor = UIColor.whiteColor;
        self.layer.zPosition = -1.f;          // Ensure the refresh control appears behind the cells, see http://stackoverflow.com/a/25829016/760435
        self.userInteractionEnabled = NO;     // Avoid conflicts with table view cell interactions when using VoiceOver
    }
    return self;
}

@end
