//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DeepLinkService.h"

#import "PlayLogger.h"
#import "PlaySRG-Swift.h"
#import "Reachability.h"

@import JavaScriptCore;
@import SRGDiagnostics;
@import SRGNetwork;
@import UIKit;

static DeepLinkService *s_currentService;

NSString * const DeepLinkDiagnosticsServiceName = @"DeepLinkDiagnosticsServiceName";

@interface DeepLinkService ()

@property (nonatomic) NSURL *serviceURL;
@property (nonatomic, weak) SRGRequest *request;

@end

@implementation DeepLinkService

#pragma mark Class methods

+ (DeepLinkService *)currentService
{
    return s_currentService;
}

+ (void)setCurrentService:(DeepLinkService *)currentService
{
    s_currentService = currentService;
}

#pragma mark Object lifecycle

- (instancetype)initWithServiceURL:(NSURL *)serviceURL
{
    if (self = [super init]) {
        self.serviceURL = serviceURL;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(reachabilityDidChange:)
                                                   name:FXReachabilityStatusDidChangeNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationWillEnterForeground:)
                                                   name:UIApplicationWillEnterForegroundNotification
                                                 object:nil];
        
        [SRGDiagnosticsService serviceWithName:DeepLinkDiagnosticsServiceName].submissionBlock = ^(NSDictionary * _Nonnull JSONDictionary, void (^ _Nonnull completionBlock)(BOOL)) {
            NSURL *diagnosticsServiceURL = [NSURL URLWithString:@"api/v1/deeplink/report" relativeToURL:serviceURL];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:diagnosticsServiceURL];
            request.HTTPMethod = @"POST";
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            request.HTTPBody = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:0 error:NULL];
            
            [[[SRGRequest dataRequestWithURLRequest:request session:NSURLSession.sharedSession completionBlock:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                BOOL success = (error == nil);
                PlayLogInfo(@"diagnostics", @"%@ report %@: %@", DeepLinkDiagnosticsServiceName, success ? @"sent" : @"not sent", JSONDictionary);
                completionBlock(success);
            }] requestWithOptions:SRGRequestOptionBackgroundCompletionEnabled] resume];
        };
        
        [self updateDeepLinkScript];
    }
    return self;
}

#pragma mark Getters and setters

- (NSURL *)customURLFromWebURL:(NSURL *)URL
{
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
    
    NSString *javaScriptFilePath = [self parsePlayURLFilePath];
    NSString *javaScript = [NSString stringWithContentsOfFile:javaScriptFilePath encoding:NSUTF8StringEncoding error:NULL];
    JSContext *context = [[JSContext alloc] init];
    [context evaluateScript:javaScript];
    JSValue *evaluate = [context objectForKeyedSubscript:@"parseForPlayApp"];
    
    NSMutableDictionary *queryItems = [NSMutableDictionary dictionary];
    [URLComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull queryItem, NSUInteger idx, BOOL * _Nonnull stop) {
        if (queryItem.value) {
            [queryItems setObject:queryItem.value forKey:queryItem.name];
        }
    }];
    JSValue *result = [evaluate callWithArguments:@[ URLComponents.scheme ?: NSNull.null,
                                                     URLComponents.host ?: NSNull.null,
                                                     URLComponents.path ?: NSNull.null,
                                                     queryItems.copy,
                                                     URLComponents.fragment ?: NSNull.null ]];
    NSString *resultString = result.toString;
    if ([resultString isEqualToString:@"null"]) {
        return nil;
    }
    
    NSURL *playURL = [NSURL URLWithString:resultString];
    if (! playURL) {
        return nil;
    }
    
    if ([playURL.host.lowercaseString isEqualToString:@"unsupported"]) {
        SRGDiagnosticReport *report = [[SRGDiagnosticsService serviceWithName:DeepLinkDiagnosticsServiceName] reportWithName:URL.absoluteString];
        [report setString:[[NSDateFormatter play_rfc3339Date] stringFromDate:NSDate.date] forKey:@"clientTime"];
        [report setString:NSBundle.mainBundle.bundleIdentifier forKey:@"clientId"];
        [report setNumber:[context objectForKeyedSubscript:@"parsePlayUrlVersion"].toNumber forKey:@"jsVersion"];
        [report setString:URL.absoluteString forKey:@"url"];
        [report finish];
        
        return nil;
    }
    
    return playURL;
}

- (NSString *)parsePlayURLFilePath
{
    if ([NSFileManager.defaultManager fileExistsAtPath:[self libraryParsePlayURLFilePath]]) {
        return [self libraryParsePlayURLFilePath];
    }
    else {
        return [NSBundle.mainBundle pathForResource:@"parsePlayUrl" ofType:@"js"];
    }
}

- (NSString *)libraryParsePlayURLFilePath
{
    NSString *libraryDirectoryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return [libraryDirectoryPath stringByAppendingPathComponent:@"parsePlayUrl.js"];
}

#pragma mark Data retrieval

- (void)updateDeepLinkScript
{
    if ([FXReachability sharedInstance].reachable && !self.request.running) {
        NSURL *URL = [NSURL URLWithString:@"api/v2/deeplink/parsePlayUrl.js" relativeToURL:self.serviceURL];
        SRGRequest *request = [SRGRequest dataRequestWithURLRequest:[NSURLRequest requestWithURL:URL] session:NSURLSession.sharedSession completionBlock:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                NSError *writeError = nil;
                [data writeToFile:[self libraryParsePlayURLFilePath] options:NSDataWritingAtomic error:&writeError];
                if (writeError) {
                    PlayLogError(@"DeepLink", @"Could not save deep linking parsing JavaScript file. Reason: %@", writeError);
                }
            }
        }];
        [request resume];
        self.request = request;
    }
}

#pragma mark Notifications

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if (ReachabilityBecameReachable(notification)) {
        [self updateDeepLinkScript];
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self updateDeepLinkScript];
}

@end
