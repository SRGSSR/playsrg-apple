//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSTimer+PlaySRG.h"

#import "TimerTarget.h"

@implementation NSTimer (PlaySRG)

+ (NSTimer *)play_timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer * _Nonnull))block
{
    NSTimer *timer = nil;
    
    if (@available(iOS 10, *)) {
        timer = [self timerWithTimeInterval:interval repeats:repeats block:block];
    }
    else {
        // Do not use self as target, since this would lead to subtle issues when the timer is deallocated
        TimerTarget *target = [[TimerTarget alloc] initWithBlock:block];
        timer = [self timerWithTimeInterval:interval target:target selector:@selector(fire:) userInfo:nil repeats:repeats];
    }
    
    // Use the recommended 10% tolerance as default, see `tolerance` documentation
    timer.tolerance = interval / 10.;
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

@end
