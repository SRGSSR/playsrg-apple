//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSTimer+PlaySRG.h"

@implementation NSTimer (PlaySRG)

+ (NSTimer *)play_timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer * _Nonnull))block
{
    NSTimer *timer = [self timerWithTimeInterval:interval repeats:repeats block:block];
    timer.tolerance = interval / 10.;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

@end
