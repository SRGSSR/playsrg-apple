//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RequestViewController.h"

#import "UIViewController+PlaySRG.h"

@import libextobjc;

@interface RequestViewController ()

@property (nonatomic) SRGRequestQueue *requestQueue;

@end

@implementation RequestViewController

#pragma mark Getters and setters

- (BOOL)isLoading
{
    return self.requestQueue.running;
}

#pragma mark View lifecycle

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self play_isMovingFromParentViewController]) {
        [self.requestQueue cancel];
    }
}

#pragma mark Overrides

- (void)refresh
{
    if (self.loading) {
        return;
    }
    
    if (! [self shouldPerformRefreshRequest]) {
        return;
    }
    
    [self.requestQueue cancel];
    
    @weakify(self)
    self.requestQueue = [[SRGRequestQueue alloc] initWithStateChangeBlock:^(BOOL finished, NSError * _Nullable error) {
        @strongify(self)
        
        if (finished) {
            [self refreshDidFinishWithError:error];
        }
        else {
            [self refreshDidStart];
        }
    }];
    [self prepareRefreshWithRequestQueue:self.requestQueue];
}

#pragma mark Stubs

- (BOOL)shouldPerformRefreshRequest
{
    return YES;
}

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue
{}

- (void)refreshDidStart
{}

- (void)refreshDidFinishWithError:(NSError *)error
{}

@end
