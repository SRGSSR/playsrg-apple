//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DataViewController.h"

@import SRGDataProviderNetwork;

NS_ASSUME_NONNULL_BEGIN

// Types
typedef void (^RequestCompletionBlock)(NSError * _Nullable error);

/**
 *  Abstract base view controller class for custom view controllers retrieving data. Subclasses must implement methods
 *  from the Subclassing category to specify the data retrieval process
 *
 *  In addition to behaviors inherited from `DataViewController`, this class provides the following features:
 *   - Clean mechanism for data retrieval
 */
@interface RequestViewController : DataViewController

/**
 *  Request the data. If a request is already running, this method does nothing
 */
- (void)refresh;

/**
 *  Return YES when data is being loaded
 */
@property (nonatomic, readonly, getter=isLoading) BOOL loading;

@end

/**
 *  Subclassing hooks
 */
@interface RequestViewController (Subclassing)

/**
 *  This method is called when a request is about to be made. The default implementation returns YES. If YES is
 *  returned and any request (refresh or loading) is currently being made, it will be cancelled first
 *
 *  @return YES if the request must be made, no otherwise
 */
- (BOOL)shouldPerformRefreshRequest;

/**
 *  When -refresh is called, this method is called with a properly created request queue. Subclasses can implement
 *  this method to add all necessary requests to this queue, and perform all required bookkeeping work they might
 *  need (e.g. saving the results of each request separately and reporting errors to the queue)
 */
- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue;

/**
 *  Called when a refresh has just started / ended
 */
- (void)refreshDidStart;
- (void)refreshDidFinishWithError:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
