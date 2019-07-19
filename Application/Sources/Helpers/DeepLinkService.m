//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DeepLinkService.h"

#import "ApplicationConfiguration.h"

#import "NSDateFormatter+PlaySRG.h"
#import "PlayLogger.h"

#import <CoconutKit/CoconutKit.h>
#import <FXReachability/FXReachability.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <SRGDiagnostics/SRGDiagnostics.h>
#import <SRGNetwork/SRGNetwork.h>

NSString * const DeepLinkDiagnosticsServiceName = @"DeepLinkDiagnosticsServiceName";

@interface DeepLinkService ()

@property (nonatomic) BOOL needAnUpdate;
@property (nonatomic, weak) SRGRequest *request;

@end

@implementation DeepLinkService

#pragma mark Class methods

+ (DeepLinkService *)sharedService
{
    static dispatch_once_t s_onceToken;
    static DeepLinkService *s_sharedService;
    dispatch_once(&s_onceToken, ^{
        s_sharedService = [[DeepLinkService alloc] init];
    });
    return s_sharedService;
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        
        self.needAnUpdate = YES;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(reachabilityDidChange:)
                                                   name:FXReachabilityStatusDidChangeNotification
                                                 object:nil];
        
        // Register for foreground notifications
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(enterForeground:)
                                                   name:UIApplicationWillEnterForegroundNotification
                                                 object:nil];
        
        [SRGDiagnosticsService serviceWithName:DeepLinkDiagnosticsServiceName].submissionBlock = ^(NSDictionary * _Nonnull JSONDictionary, void (^ _Nonnull completionBlock)(BOOL)) {
            NSURL *middlewareURL = ApplicationConfiguration.sharedApplicationConfiguration.middlewareURL;
            NSURL *diagnosticsServiceURL = [NSURL URLWithString:@"api/v1/deeplink/report" relativeToURL:middlewareURL];
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
    }
    return self;
}

- (void)setup
{
    [self updateDeepLinkScript];
}

#pragma mark Getters and setters

- (NSURL *)schemeURLFromWebURL:(NSURL *)URL
{
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
    
    NSString *javascriptFilePath = [self parsePlayUrlFilePath];
    NSString *javascript = [NSString stringWithContentsOfFile:javascriptFilePath encoding:NSUTF8StringEncoding error:nil];
    JSContext *context = [[JSContext alloc] init];
    [context evaluateScript:javascript];
    JSValue * evaluate = [context objectForKeyedSubscript:@"parseForPlayApp"];
    
    NSMutableDictionary *queryItems = [NSMutableDictionary dictionary];
    [URLComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull queryItem, NSUInteger idx, BOOL * _Nonnull stop) {
        if (queryItem.value) {
            [queryItems setObject:queryItem.value forKey:queryItem.name];
        }
    }];
    JSValue * result = [evaluate callWithArguments:@[ URLComponents.host ?: NSNull.null,
                                                      URLComponents.path ?: NSNull.null,
                                                      queryItems.copy,
                                                      URLComponents.fragment ?: NSNull.null ]];
    NSURL *playURL = [NSURL URLWithString:result.toString];
    
    if ([playURL.host.lowercaseString isEqualToString:@"redirect"]) {
        SRGDiagnosticReport *report = [[SRGDiagnosticsService serviceWithName:DeepLinkDiagnosticsServiceName] reportWithName:URL.absoluteString];
        [report setString:[[NSDateFormatter play_backendDateFormatter] stringFromDate:NSDate.date] forKey:@"clientTime"];
        [report setString:NSBundle.mainBundle.bundleIdentifier forKey:@"clientId"];
        [report setString:[context objectForKeyedSubscript:@"parsePlayUrlVersion"].toString forKey:@"jsVersion"];
        [report setString:URL.absoluteString forKey:@"url"];
        [report finish];
        
        playURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://open", playURL.scheme]];
    }
    
    return playURL;
}

- (NSString *)parsePlayUrlFilePath
{
    if ([NSFileManager.defaultManager fileExistsAtPath:[self libraryParsePlayUrlFilePath]]) {
        return [self libraryParsePlayUrlFilePath];
    }
    else {
        return  [NSBundle.mainBundle pathForResource:@"parse_play_url" ofType:@"js"];
    }
}

- (NSString *)libraryParsePlayUrlFilePath
{
    return [HLSApplicationLibraryDirectoryPath() stringByAppendingPathComponent:@"parse_play_url.js"];
}

#pragma mark Data retrieval

- (void)updateDeepLinkScript
{
    if (self.needAnUpdate && [FXReachability sharedInstance].reachable && !self.request.running) {
        NSURL *middlewareURL = ApplicationConfiguration.sharedApplicationConfiguration.middlewareURL;
        NSURL *URL = [NSURL URLWithString:@"api/v1/deeplink/parse_play_url.js" relativeToURL:middlewareURL];
        
        SRGRequest *request = [SRGRequest dataRequestWithURLRequest:[NSURLRequest requestWithURL:URL] session:NSURLSession.sharedSession completionBlock:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                NSError *writeError = nil;
                [data writeToFile:[self libraryParsePlayUrlFilePath] options:NSDataWritingAtomic error:&writeError];
                if (writeError) {
                    PlayLogError(@"DeepLink", @"Could not save parse_play_url.js file. Reason: %@", writeError);
                    NSAssert(NO, @"Could not save parse_play_url.js file. Not safe. See error above.");
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
    if ([FXReachability sharedInstance].reachable) {
        [self updateDeepLinkScript];
    }
}

- (void)enterForeground:(NSNotification *)notification
{
    self.needAnUpdate = YES;
    [self updateDeepLinkScript];
}

@end

__attribute__((constructor)) static void DeepLinkServiceInit(void)
{
    [DeepLinkService.sharedService setup];
}
