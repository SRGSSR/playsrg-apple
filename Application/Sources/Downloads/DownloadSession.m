//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DownloadSession.h"

#import "Download+Private.h"
#import "PlayLogger.h"
#import "Reachability.h"

@import libextobjc;
@import SRGLogger;

NSString * const DownloadSessionStateDidChangeNotification = @"DownloadSessionStateDidChangeNotification";
NSString * const DownloadSessionStateKey = @"DownloadSessionState";

NSString * const DownloadProgressDidChangeNotification = @"DownloadProgressDidChangeNotification";
NSString * const DownloadProgressKey = @"DownloadProgress";

@interface DownloadSession ()

@property (nonatomic) NSURLSession *session;

@property (nonatomic) NSMutableDictionary<NSNumber *, Download *> *downloads;
@property (nonatomic) NSMutableDictionary<NSNumber *, NSProgress *> *progresses;

@property (nonatomic) DownloadSessionState state;

@end

@implementation DownloadSession

@synthesize state = _state;

#pragma mark Class methods

+ (DownloadSession *)sharedDownloadSession
{
    static DownloadSession *s_downloadSession;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_downloadSession = [DownloadSession new];
    });
    return s_downloadSession;
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"ch.srgssr.play.downloads"];
        configuration.allowsCellularAccess = YES;
        configuration.discretionary = NO;
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        
        self.downloads = [NSMutableDictionary new];
        self.progresses = [NSMutableDictionary new];
        
        self.state = DownloadSessionStateIdle;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(reachabilityDidChange:)
                                                   name:FXReachabilityStatusDidChangeNotification
                                                 object:nil];
    }
    return self;
}

#pragma mark Getters and setters

- (void)setState:(DownloadSessionState)state
{
    if (_state == state) {
        return;
    }
    
    _state = state;
    
    [NSNotificationCenter.defaultCenter postNotificationName:DownloadSessionStateDidChangeNotification
                                                      object:self
                                                    userInfo:@{DownloadSessionStateKey : @(state)}];
}

- (void)setNeedsStateUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.downloads.count != 0) {
            self.state = [FXReachability isReachable] ? DownloadSessionStateDownloading : DownloadSessionStateDownloadingSuspended;
        }
        else {
            self.state = DownloadSessionStateIdle;
        }
    });
}

#pragma mark Download management

- (BOOL)addDownload:(Download *)download
{
    NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(Download.new, URN)];
    if ([[self.downloads.allValues valueForKeyPath:keyPath] containsObject:download.URN]) {
        return NO;
    }
    
    BOOL added = NO;
    
    if (! download.localImageFileURL) {
        NSURLSessionDownloadTask *imageFileTask = [self.session downloadTaskWithURL:download.downloadImageURL];
        self.downloads[@(imageFileTask.taskIdentifier)] = download;
        [imageFileTask resume];
        added = YES;
    }
    
    if (! download.localMediaFileURL) {
        NSURLSessionDownloadTask *mediaFileTask = [self.session downloadTaskWithURL:download.downloadMediaURL];
        self.downloads[@(mediaFileTask.taskIdentifier)] = download;
        [mediaFileTask resume];
        added = YES;
    }
    
    [self setNeedsStateUpdate];
    
    return added;
}

- (void)restoreSessionState
{
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        NSMutableDictionary *copyDownloads = self.downloads.mutableCopy;
        // Enumerate all download tasks
        [downloadTasks enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull downloadTask, NSUInteger idx, BOOL * _Nonnull stop) {
            // Resume found task
            if (copyDownloads[@(downloadTask.taskIdentifier)]) {
                copyDownloads[@(downloadTask.taskIdentifier)] = nil;
                [downloadTask resume];
            }
            // Cancel non registered task
            else {
                [downloadTask cancel];
            }
        }];
        
        // Get missing Downloads
        NSSet<Download *> *missingDownloads = [NSSet setWithArray:copyDownloads.allValues];
        
        // Clean registered tasks
        [copyDownloads enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            self.downloads[key] = nil;
            self.progresses[key] = nil;
        }];
        
        [missingDownloads enumerateObjectsUsingBlock:^(Download * _Nonnull download, BOOL * _Nonnull stop) {
            [self addDownload:download];
        }];
        
        [self setNeedsStateUpdate];
    }];
}

- (void)removeDownload:(Download *)download
{
    NSArray *keys = [self.downloads.copy allKeysForObject:download];
    if (keys.count != 0) {
        [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
            [downloadTasks enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([keys containsObject:@(task.taskIdentifier)]) {
                    self.downloads[@(task.taskIdentifier)] = nil;
                    [task cancel];
                };
            }];
            
            [self setNeedsStateUpdate];
        }];
    }
}

- (BOOL)hasTasksForDownload:(Download *)download
{
    return [self.downloads allKeysForObject:download].count != 0;
}

- (BOOL)isDownloadingDownload:(Download *)download {
    return [self hasTasksForDownload:download] && [FXReachability isReachable];
}

- (nullable NSProgress *)currentlyKnownProgressForDownload:(Download *)download {
    NSArray<NSNumber *> *keys = [self.downloads allKeysForObject:download];
    for (NSNumber *key in keys) {
        if (self.progresses[key]) {
            return self.progresses[key];
        }
    }
    return nil;
}

#pragma mark NSURLSessionDownloadDelegate protocol

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *key = @(downloadTask.taskIdentifier);
        
        Download *download = self.downloads[key];
        if ([downloadTask.originalRequest.URL isEqual:download.downloadMediaURL]) {
            NSProgress *progress = self.progresses[key];
            if (! progress) {
                progress = [NSProgress progressWithTotalUnitCount:totalBytesExpectedToWrite];
                self.progresses[key] = progress;
            }
            progress.totalUnitCount = totalBytesExpectedToWrite;
            progress.completedUnitCount = totalBytesWritten;
            
            // Send notifications on behalf of the download
            [NSNotificationCenter.defaultCenter postNotificationName:DownloadProgressDidChangeNotification
                                                              object:download
                                                            userInfo:@{ DownloadProgressKey : progress }];
        }
    });
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSNumber *key = @(downloadTask.taskIdentifier);
    Download *download = self.downloads[key];
    
    if (download && [downloadTask.response isKindOfClass:NSHTTPURLResponse.class] && ((NSHTTPURLResponse *)downloadTask.response).statusCode == 200) {
        if ([downloadTask.originalRequest.URL isEqual:download.downloadMediaURL]) {
            [download setLocalMediaFileWithTmpFile:location MIMEType:downloadTask.response.MIMEType];
        }
        else if ([downloadTask.originalRequest.URL isEqual:download.downloadImageURL]) {
            [download setLocalImageFileWithTmpFile:location MIMEType:downloadTask.response.MIMEType];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloads[key] = nil;
        self.progresses[key] = nil;
        
        [self setNeedsStateUpdate];
        
        [download setNeedsStateUpdate];
    });
}

#pragma mark NSURLSessionTaskDelegate protocol

// Called with resume data at application start, if the application was killed by the user
// See http://stackoverflow.com/a/32946198/760435
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // If resume data is available and can be bound to a download, replace any running task with a task starting from this
    // data. This is not optimal, but since downloads are restarted before this delegate method is called, there is no reliable
    // way of knowing whether resume data was available earlier. This should not harm, though, as this method should be called
    // early after downloads have been restarted, probably before any data has been transferred
    NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    if (resumeData) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(Download.new, downloadMediaURL), task.originalRequest.URL];
        Download *download = [Download.downloads filteredArrayUsingPredicate:predicate].firstObject;
        if (download) {
            [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
                [downloadTasks enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([task.originalRequest.URL isEqual:download.downloadMediaURL] && task.state == NSURLSessionTaskStateRunning) {
                        // Cancel the original request
                        self.downloads[@(task.taskIdentifier)] = nil;
                        [task cancel];
                        
                        // Replace with a new one using the resume data
                        NSURLSessionDownloadTask *mediaFileTask = [self.session downloadTaskWithResumeData:resumeData];
                        self.downloads[@(mediaFileTask.taskIdentifier)] = download;
                        [mediaFileTask resume];
                        
                        [self setNeedsStateUpdate];
                        
                        *stop = YES;
                    }
                }];
            }];
        }
    }
    else if (error) {
        PlayLogError(@"download", @"Could not finish download correctly for %@. Reason: %@", task.originalRequest.URL.absoluteString, error);
        
        NSNumber *key = @(task.taskIdentifier);
        Download *download = self.downloads[key];
        
        // If error occured (like a network error or SSL error), remove the download.
        if (download) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.downloads[key] = nil;
                self.progresses[key] = nil;
                
                [self setNeedsStateUpdate];
                
                [download setNeedsStateUpdate];
            });
        }
    }
}

#pragma mark Notifications

- (void)reachabilityDidChange:(NSNotification *)notification
{
    [self setNeedsStateUpdate];
    
    NSSet<Download *> *downloadsSet = [NSSet setWithArray:[self.downloads allValues]];
    [downloadsSet enumerateObjectsUsingBlock:^(Download * _Nonnull download, BOOL * _Nonnull stop) {
        [download setNeedsStateUpdate];
    }];
    
    if (ReachabilityBecameReachable(notification)) {
        [self restoreSessionState];
    }
}

@end
