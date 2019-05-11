//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DeeplinkService.h"

#import "ApplicationConfiguration.h"

#import "PlayLogger.h"

#import <CoconutKit/CoconutKit.h>
#import <FXReachability/FXReachability.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <SRGNetwork/SRGNetwork.h>

@interface DeeplinkService ()

@property (nonatomic) BOOL needAnUpdate;
@property (nonatomic, weak) SRGRequest *request;

@end

@implementation DeeplinkService

#pragma mark Class methods

+ (DeeplinkService *)sharedService
{
    static dispatch_once_t s_onceToken;
    static DeeplinkService *s_sharedService;
    dispatch_once(&s_onceToken, ^{
        s_sharedService = [[DeeplinkService alloc] init];
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
    }
    return self;
}

- (void)setup
{
    [self updateDeeplinkScript];
}

#pragma mark Getters and setters

- (NSURL *)schemeURLFromWebURL:(NSURL *)url
{
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
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
        // TODO: Send the URL to the deeplink service, for analyse.
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

- (void)updateDeeplinkScript
{
    if (self.needAnUpdate && [FXReachability sharedInstance].reachable && !self.request.running) {
        NSString *resourcePath = @"deeplink/v1/parse_play_url.js";
        NSURL *middlewareURL = ApplicationConfiguration.sharedApplicationConfiguration.middlewareURL;
        NSURL *URL = [NSURL URLWithString:resourcePath relativeToURL:middlewareURL];
        
        SRGRequest *request = [SRGRequest dataRequestWithURLRequest:[NSURLRequest requestWithURL:URL] session:NSURLSession.sharedSession completionBlock:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                NSError *writeError = nil;
                [data writeToFile:[self libraryParsePlayUrlFilePath] options:NSDataWritingAtomic error:&writeError];
                if (writeError) {
                    PlayLogError(@"Deeplink", @"Could not save parse_play_url.js file. Reason: %@", writeError);
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
        [self updateDeeplinkScript];
    }
}

- (void)enterForeground:(NSNotification *)notification
{
    self.needAnUpdate = YES;
    [self updateDeeplinkScript];
}

@end

__attribute__((constructor)) static void DeeplinkServiceInit(void)
{
    [DeeplinkService.sharedService setup];
}
