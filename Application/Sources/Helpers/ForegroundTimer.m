//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ForegroundTimer.h"

#import "NSTimer+PlaySRG.h"

@import libextobjc;
@import UIKit;

@interface ForegroundTimer ()

@property (nonatomic) NSTimeInterval interval;
@property (nonatomic) BOOL repeats;
@property (nonatomic, copy) void (^block)(ForegroundTimer *);

@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSDate *nextFireDate;

@end

@implementation ForegroundTimer

#pragma mark Class methods

+ (ForegroundTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                                   repeats:(BOOL)repeats
                                     block:(void (^)(ForegroundTimer * _Nonnull))block
{
    return [[ForegroundTimer alloc] initWithTimeInterval:interval repeats:repeats block:block];
}

#pragma mark Object lifecycle

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval
                             repeats:(BOOL)repeats
                               block:(void (^)(ForegroundTimer * _Nonnull))block
{
    if (self = [super init]) {
        self.interval = interval;
        self.repeats = repeats;
        self.block = block;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationDidEnterBackground:)
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationWillEnterForeground:)
                                                   name:UIApplicationWillEnterForegroundNotification
                                                 object:nil];
        
        [self resume];
    }
    return self;
}

- (void)dealloc
{
    self.timer = nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithTimeInterval:0. repeats:NO block:^(ForegroundTimer * _Nonnull timer) {}];
}

#pragma clang diagnostic pop

#pragma mark Getters and setters

- (void)setTimer:(NSTimer *)timer
{
    [_timer invalidate];
    _timer = timer;
}

#pragma mark Timer management

- (void)invalidate
{
    self.timer = nil;
}

- (void)resume
{
    if (self.nextFireDate) {
        NSTimeInterval interval = [NSDate.date timeIntervalSinceDate:self.nextFireDate];
        if (interval >= 0) {
            self.block(self);
            
            if (self.repeats) {
                self.timer = [NSTimer play_timerWithTimeInterval:self.interval repeats:YES block:^(NSTimer * _Nonnull timer) {
                    self.block(self);
                }];
            }
        }
        else {
            self.timer = [NSTimer play_timerWithTimeInterval:-interval repeats:NO block:^(NSTimer * _Nonnull timer) {
                self.block(self);
                
                if (self.repeats) {
                    self.timer = [NSTimer play_timerWithTimeInterval:self.interval repeats:YES block:^(NSTimer * _Nonnull timer) {
                        self.block(self);
                    }];
                }
            }];
        }
        self.nextFireDate = nil;
    }
    else {
        self.timer = [NSTimer play_timerWithTimeInterval:self.interval repeats:self.repeats block:^(NSTimer * _Nonnull timer) {
            self.block(self);
        }];
    }
}

- (void)suspend
{
    self.nextFireDate = self.timer.fireDate;
    self.timer = nil;
}

#pragma mark Notifications

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self suspend];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self resume];
}

@end
