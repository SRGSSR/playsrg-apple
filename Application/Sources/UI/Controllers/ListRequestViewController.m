//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ListRequestViewController.h"

#import "PlaySRG-Swift.h"
#import "UIViewController+PlaySRG.h"

@import libextobjc;

static void commonInit(ListRequestViewController *self);

@interface ListRequestViewController ()

@property (nonatomic) SRGRequestQueue *requestQueue;

@property (nonatomic) NSUInteger numberOfLoadedPages;
@property (nonatomic) NSArray *loadedItems;
@property (nonatomic) SRGPage *nextPage;

@property (nonatomic) NSMutableArray *hiddenItems;
@property (nonatomic) NSArray *cachedItems;

@end

@implementation ListRequestViewController

#pragma mark Object lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Getters and setters

- (NSArray *)items
{
    if (! self.cachedItems) {
        self.cachedItems = [self.loadedItems arrayByRemovingObjectsIn:self.hiddenItems];
    }
    return self.cachedItems;
}

- (BOOL)isLoading
{
    return self.requestQueue.running;
}

- (BOOL)canLoadMoreItems
{
    return self.nextPage != nil;
}

#pragma mark View lifecycle

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self play_isMovingFromParentViewController]) {
        [self.requestQueue cancel];
    }
}

#pragma mark Data

- (void)refresh
{
    if (self.loading) {
        return;
    }
    
    if (! [self shouldPerformRefreshRequest]) {
        [self didCancelRefreshRequest];
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
    
    NSMutableArray *loadingItems = [NSMutableArray array];
    
    __block SRGPage *loadingNextPage = nil;
    __block NSUInteger remainingNextPageRequests = (self.numberOfLoadedPages > 0) ? self.numberOfLoadedPages - 1 : 0;
    __block NSUInteger numberOfLoadedPages = 0;
    
    typedef void (^LoadPageBlock)(SRGPage * _Nullable);
    __block __weak LoadPageBlock weakLoadPage = nil;
    
    LoadPageBlock loadPage = ^(SRGPage * _Nullable page) {
        LoadPageBlock strongLoadPage = weakLoadPage;
        
        [self loadPage:page withCompletionBlock:^(NSArray * _Nullable items, SRGPage * _Nullable nextPage, NSError * _Nullable error) {
            if (error) {
                return;
            }
            
            [loadingItems addObjectsFromArray:items];
            loadingNextPage = nextPage;
            
            ++numberOfLoadedPages;
            
            if (remainingNextPageRequests > 0 && nextPage) {
                --remainingNextPageRequests;
                strongLoadPage(nextPage);
            }
            else {
                self.loadedItems = loadingItems.copy;
                self.cachedItems = nil;         // Invalidate cache
                
                self.nextPage = loadingNextPage;
                self.numberOfLoadedPages = numberOfLoadedPages;
            }
        }];
    };
    weakLoadPage = loadPage;
    
    loadPage(nil);
}

- (void)loadNextPage
{
    if (self.loading || ! self.nextPage) {
        return;
    }
    
    [self loadPage:self.nextPage withCompletionBlock:^(NSArray * _Nullable items, SRGPage * _Nullable nextPage, NSError * _Nullable error) {
        if (error) {
            return;
        }
        
        self.loadedItems = [self.loadedItems arrayByAddingObjectsFromArray:items];
        self.cachedItems = nil;         // Invalidate cache
        
        self.nextPage = nextPage;
        ++self.numberOfLoadedPages;
    }];
}

- (void)clear
{
    [self.requestQueue cancel];
    
    [self refreshDidStart];
    
    self.loadedItems = nil;
    self.nextPage = nil;
    self.numberOfLoadedPages = 0;
    
    self.hiddenItems = [NSMutableArray array];
    self.cachedItems = nil;
    
    [self refreshDidFinishWithError:nil];
}

- (void)loadPage:(SRGPage *)page withCompletionBlock:(void (^)(NSArray * _Nullable items, SRGPage * _Nullable nextPage, NSError * _Nullable error))completionBlock
{
    NSParameterAssert(completionBlock);
    
    [self prepareRefreshWithRequestQueue:self.requestQueue page:page completionHandler:^(NSArray * _Nullable items, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        if (error) {
            [self.requestQueue reportError:error];
            return;
        }
        
        completionBlock(items, nextPage, error);
    }];
}

#pragma mark Item hiding

- (void)hideItems:(NSArray *)items
{
    [self.hiddenItems addObjectsFromArray:items];
    self.cachedItems = nil;         // Invalidate cache
}

- (void)unhideItems:(NSArray *)items
{
    [self.hiddenItems removeObjectsInArray:items];
    self.cachedItems = nil;         // Invalidate cache
}

#pragma mark Stubs

- (BOOL)shouldPerformRefreshRequest
{
    return YES;
}

- (void)didCancelRefreshRequest
{}

- (SRGRequest *)requestForListWithCompletionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    [self doesNotRecognizeSelector:_cmd];
    return [SRGRequest new];
}

- (void)refreshDidStart
{}

- (void)refreshDidFinishWithError:(NSError *)error
{}

@end

static void commonInit(ListRequestViewController *self)
{
    self.hiddenItems = [NSMutableArray array];
}
