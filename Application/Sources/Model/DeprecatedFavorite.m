//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DeprecatedFavorite+Private.h"

#import "ApplicationConfiguration.h"
#import "Download.h"
#import "NSDateFormatter+PlaySRG.h"
#import "PlayErrors.h"
#import "PlayLogger.h"

#import <CoconutKit/CoconutKit.h>
#import <libextobjc/libextobjc.h>
#import <SRGLogger/SRGLogger.h>

static NSString *FavoriteIdentifier(FavoriteType type, NSString *uid);

NSString * const FavoriteStateDidChangeNotification = @"FavoriteStateDidChangeNotification";
NSString * const FavoriteObjectKey = @"FavoriteObject";
NSString * const FavoriteStateKey = @"FavoriteState";

CGFloat const FavoriteBackupImageWidth = 150.f;

static NSMutableDictionary<NSString *, DeprecatedFavorite *> *s_favoritesDictionary;
static NSArray<DeprecatedFavorite *> *s_sortedFavorites;

@protocol Favoriting <NSObject>

@property (nonatomic, readonly, copy) NSString *favoriteIdentifier;

@property (nonatomic, readonly) FavoriteType favoriteType;
@property (nonatomic, readonly, copy) NSString *favoriteUid;
@property (nonatomic, readonly, copy) NSString *favoriteTitle;

@property (nonatomic, readonly) FavoriteMediaType favoriteMediaType;
@property (nonatomic, readonly, copy) NSString *favoriteMediaURN;
@property (nonatomic, readonly) FavoriteMediaContentType favoriteMediaContentType;
@property (nonatomic, readonly, copy) NSDate *favoriteDate;
@property (nonatomic, readonly) NSTimeInterval favoriteDuration;
@property (nonatomic, readonly) SRGPresentation favoritePresentation;
@property (nonatomic, readonly, copy) NSString *favoriteShowTitle;
@property (nonatomic, readonly, copy) NSDate *favoriteStartDate;
@property (nonatomic, readonly, copy) NSDate *favoriteEndDate;
@property (nonatomic, readonly) SRGYouthProtectionColor favoriteYouthProtectionColor;

@property (nonatomic, readonly, copy) NSString *favoriteShowURN;
@property (nonatomic, readonly) FavoriteShowTransmission favoriteShowTransmission;

- (NSURL *)favoriteImageURLForDimension:(SRGImageDimension)dimension withValue:(CGFloat)value;
@property (nonatomic, readonly, copy) NSString *favoriteImageTitle;
@property (nonatomic, readonly, copy) NSString *favoriteImageCopyright;

@end

@interface DeprecatedFavorite ()

@property (nonatomic) id<Favoriting> object;
@property (nonatomic) NSDate *creationDate;

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic) FavoriteType type;
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *title;

@property (nonatomic) FavoriteMediaType mediaType;
@property (nonatomic, copy) NSString *mediaURN;
@property (nonatomic) FavoriteMediaContentType mediaContentType;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) SRGPresentation presentation;
@property (nonatomic, copy) NSString *showTitle;
@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *endDate;
@property (nonatomic) SRGYouthProtectionColor youthProtectionColor;

@property (nonatomic, copy) NSString *showURN;
@property (nonatomic) FavoriteShowTransmission showTransmission;

@property (nonatomic) NSURL *imageURL;
@property (nonatomic, copy) NSString *imageTitle;
@property (nonatomic, copy) NSString *imageCopyright;

@property (nonatomic, readonly) NSDictionary *backupDictionary;

@end

// Types with favorite support

@interface SRGMedia (FavoriteSupport) <Favoriting>

@end

@interface SRGShow (FavoriteSupport) <Favoriting>

@end

@implementation DeprecatedFavorite

#pragma mark Class methods

+ (NSString *)favoritesFilePath
{
    return [HLSApplicationLibraryDirectoryPath() stringByAppendingPathComponent:@"favorites.plist"];
}

+ (NSDictionary<NSString *, DeprecatedFavorite *> *)loadFavoritesDictionary
{
    NSDictionary<NSString *, DeprecatedFavorite *> *favoritesDictionary = [NSKeyedUnarchiver unarchiveObjectWithFile:[self favoritesFilePath]];
    
    NSPredicate *isNotNSString= [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return ![evaluatedObject isKindOfClass:NSString.class];
    }];
    NSPredicate *isNotFavorite = [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return ![evaluatedObject isKindOfClass:DeprecatedFavorite.class];
    }];
    
    // Return the loaded dictionnary iff it contains expected objects
    return (! [favoritesDictionary.allKeys filteredArrayUsingPredicate:isNotNSString].count &&
            ! [favoritesDictionary.allValues filteredArrayUsingPredicate:isNotFavorite].count)
    ? favoritesDictionary : nil;
}

+ (void)saveFavoritesDictionary
{
    [NSKeyedArchiver archiveRootObject:s_favoritesDictionary toFile:[self favoritesFilePath]];
    [self saveFavoritesBackupDictionary];
}

+ (NSString *)favoritesBackupFilePath
{
    return [HLSApplicationLibraryDirectoryPath() stringByAppendingPathComponent:@"favoritesBackup.plist"];
}

+ (NSDictionary<NSString *, DeprecatedFavorite *> *)loadFavoritesBackupDictionary
{
    NSMutableDictionary *favoritesBackupDictionary = [NSMutableDictionary dictionary];
    NSDictionary *backupFileDictionnary = [NSDictionary dictionaryWithContentsOfFile:[self favoritesBackupFilePath]];
    [backupFileDictionnary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            NSDictionary *favoriteDictionary = (NSDictionary *)obj;
            DeprecatedFavorite *favorite = [[DeprecatedFavorite alloc] initWithDictionary:favoriteDictionary];
            if (favorite && [key isEqualToString:favorite.identifier]) {
                favoritesBackupDictionary[key] = favorite;
            }
            else {
                PlayLogError(@"favorite", @"Could not open favorite for key %@. Skipped", key);
            }
        }
    }];
    
    return favoritesBackupDictionary.copy;
}

+ (void)saveFavoritesBackupDictionary
{
    NSMutableDictionary *favoritesBackupDictionary = [NSMutableDictionary dictionary];
    [s_favoritesDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, DeprecatedFavorite * _Nonnull favorite, BOOL * _Nonnull stop) {
        favoritesBackupDictionary[key] = favorite.backupDictionary;
    }];
    
    NSError *plistError = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:favoritesBackupDictionary
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:&plistError];
    if (plistError) {
        PlayLogError(@"favorite", @"Could not save favorites backup data. Reason: %@", plistError);
        NSAssert(NO, @"Could not save favorites backup data. Not safe. See error above.");
        return;
    }
    
    NSError *writeError = nil;
    [plistData writeToFile:[self favoritesBackupFilePath] options:NSDataWritingAtomic error:&writeError];
    if (writeError) {
        PlayLogError(@"favorite", @"Could not save favorites data. Reason: %@", writeError);
        NSAssert(NO, @"Could not save favorites backup data. Not safe. See error above.");
    }
}

+ (NSArray<DeprecatedFavorite *> *)favorites
{
    if (! s_sortedFavorites) {
        NSSortDescriptor *typeSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(DeprecatedFavorite.new, type) ascending:YES comparator:^NSComparisonResult(id _Nonnull object1, id _Nonnull object2) {
            NSInteger type1 = [object1 integerValue];
            NSInteger type2 = [object2 integerValue];
            if (type1 == type2) {
                return NSOrderedSame;
            }
            else if (type1 == FavoriteTypeShow) {
                return NSOrderedAscending;
            }
            else if (type2 == FavoriteTypeShow) {
                return NSOrderedDescending;
            }
            else {
                return NSOrderedSame;
            }
        }];
        NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(DeprecatedFavorite.new, creationDate) ascending:NO];
        s_sortedFavorites = [s_favoritesDictionary.allValues sortedArrayUsingDescriptors:@[typeSortDescriptor, dateSortDescriptor]];
    }
    return s_sortedFavorites;
}

+ (DeprecatedFavorite *)addFavoriteForObject:(id<Favoriting>)object
{
    DeprecatedFavorite *favorite = [self favoriteForObject:object];
    if (favorite) {
        return favorite;
    }
    
    favorite = [[DeprecatedFavorite alloc] initWithObject:object];
    s_favoritesDictionary[object.favoriteIdentifier] = favorite;
    s_sortedFavorites = nil;            // Invalidate sorted favorite cache
    
    [self saveFavoritesDictionary];
    
    [NSNotificationCenter.defaultCenter postNotificationName:FavoriteStateDidChangeNotification
                                                      object:nil
                                                    userInfo:@{ FavoriteObjectKey : favorite,
                                                                FavoriteStateKey : @YES }];
    
    return favorite;
}

// Add a favorite object directly.
// Not public. No notification. only use at launch
// Use addFavoriteForObject:
+ (BOOL)addFavorite:(DeprecatedFavorite *)favorite;
{
    DeprecatedFavorite *existingFavorite = s_favoritesDictionary[favorite.identifier];
    if (existingFavorite) {
        return NO;
    }
    
    s_favoritesDictionary[favorite.identifier] = favorite;
    s_sortedFavorites = nil;            // Invalidate sorted favorite cache
    
    [self saveFavoritesDictionary];
    
    if (! favorite.object) {
        // Cache the associated object
        [favorite objectForType:FavoriteTypeUnspecified available:NULL withCompletionBlock:^(id  _Nullable favoritedObject, NSError * _Nullable error) {}];
    }
    
    return YES;
}

+ (void)removeFavorite:(DeprecatedFavorite *)favorite;
{
    if (! favorite.identifier || ! s_favoritesDictionary[favorite.identifier]) {
        return;
    }
    
    [s_favoritesDictionary removeObjectForKey:favorite.identifier];
    s_sortedFavorites = nil;            // Invalidate sorted favorite cache
    
    [self saveFavoritesDictionary];
    
    [NSNotificationCenter.defaultCenter postNotificationName:FavoriteStateDidChangeNotification
                                                      object:nil
                                                    userInfo:@{ FavoriteObjectKey : favorite,
                                                                FavoriteStateKey : @NO}];
}

+ (DeprecatedFavorite *)toggleFavoriteForMedia:(SRGMedia *)media
{
    return [DeprecatedFavorite toggleFavoriteForObject:media];
}

+ (DeprecatedFavorite *)toggleFavoriteForShow:(SRGShow *)show
{
    return [DeprecatedFavorite toggleFavoriteForObject:show];
}

+ (DeprecatedFavorite *)toggleFavoriteForObject:(id<Favoriting>)object
{
    DeprecatedFavorite *favorite = [self favoriteForObject:object];
    if (favorite) {
        [self removeFavorite:favorite];
        return nil;
    }
    else {
        return [self addFavoriteForObject:object];
    }
}

+ (DeprecatedFavorite *)favoriteForMedia:(SRGMedia *)media
{
    return [DeprecatedFavorite favoriteForObject:media];
}

+ (DeprecatedFavorite *)favoriteForShow:(SRGShow *)show
{
    return [DeprecatedFavorite favoriteForObject:show];
}

+ (DeprecatedFavorite *)favoriteForObject:(id<Favoriting>)object
{
    if (! object) {
        return nil;
    }
    
    DeprecatedFavorite *favorite = s_favoritesDictionary[object.favoriteIdentifier];
    
    // Update favorite with the object
    if (favorite && !favorite.object) {
        [favorite updateWithObject:object];
        [self saveFavoritesDictionary];
    }
    
    return favorite;
}

+ (void)removeAllFavorites
{
    NSArray <DeprecatedFavorite *> *favorites = s_favoritesDictionary.allValues;
    
    [s_favoritesDictionary removeAllObjects];
    s_sortedFavorites = nil;
    
    [self saveFavoritesDictionary];
    
    [favorites enumerateObjectsUsingBlock:^(DeprecatedFavorite * _Nonnull favorite, NSUInteger idx, BOOL * _Nonnull stop) {
        [NSNotificationCenter.defaultCenter postNotificationName:FavoriteStateDidChangeNotification
                                                          object:nil
                                                        userInfo:@{ FavoriteObjectKey : favorite,
                                                                    FavoriteStateKey : @NO }];
    }];
}

#pragma mark Object lifecycle

- (instancetype)initWithObject:(id)object
{
    if (self = [super init]) {
        self.object = object;
        self.creationDate = NSDate.date;
        
        [self updateWithObject:object];
    }
    return self;
}

// Initializer from the plist backup
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    NSString *uid = dictionary[@"uid"];
    NSString *title = dictionary[@"title"];
    
    // At least a uid and a title must be guaranteed
    if (uid.length == 0 || title.length == 0) {
        PlayLogError(@"favorite", @"Missing favorite identifier or title");
        return nil;
    }
    
    // The type must be known as well
    FavoriteType type = [dictionary[@"type"] integerValue];
    if (type == FavoriteTypeUnspecified) {
        PlayLogError(@"favorite", @"Missing favorite type");
        return nil;
    }
    
    // We must be able to build a unique identifier as well
    NSString *identifier = FavoriteIdentifier(type, uid);
    if (! identifier) {
        PlayLogError(@"favorite", @"Could not create favorite identifier");
        return nil;
    }
    
    if (self = [super init]) {
        // No object assigned here
        
        self.creationDate = dictionary[@"creationDate"] ?: NSDate.date;
        
        self.identifier = identifier;
        
        self.type = type;
        self.uid = uid;
        self.title = title;
        
        self.mediaType = [dictionary[@"mediaType"] integerValue];
        self.mediaURN = dictionary[@"mediaURN"] ?: dictionary[@"URN"]; // Backup file from version < 2.7.6 uses URN, instead of mediaURN
        self.mediaContentType = [dictionary[@"mediaContentType"] integerValue];
        self.date = dictionary[@"date"];
        self.duration = [dictionary[@"duration"] integerValue];
        self.presentation = [dictionary[@"presentation"] integerValue];
        self.showTitle = dictionary[@"showTitle"];
        self.startDate = dictionary[@"startDate"];
        self.endDate = dictionary[@"endDate"];
        
        self.showURN = dictionary[@"showURN"];
        self.showTransmission = [dictionary[@"showTransmission"] integerValue];
        
        self.imageURL = [NSURL URLWithString:dictionary[@"imageURL"]];
        self.imageTitle = dictionary[@"imageTitle"];
        self.imageCopyright = dictionary[@"imageCopyright"];
    }
    
    return self;
}

#pragma mark Setters

- (void)updateWithObject:(id<Favoriting>)object
{
    if (! object) {
        return;
    }
    
    self.object = object;
    
    self.identifier = object.favoriteIdentifier;
    
    self.type = object.favoriteType;
    self.uid = object.favoriteUid;
    self.title = object.favoriteTitle;
    
    self.mediaType = object.favoriteMediaType;
    self.mediaURN = object.favoriteMediaURN;
    self.mediaContentType = object.favoriteMediaContentType;
    self.date = object.favoriteDate;
    self.duration = object.favoriteDuration;
    self.presentation = object.favoritePresentation;
    self.showTitle = object.favoriteShowTitle;
    self.startDate = object.favoriteStartDate;
    self.endDate = object.favoriteEndDate;
    self.youthProtectionColor = object.favoriteYouthProtectionColor;
    self.showURN = object.favoriteShowURN;
    self.showTransmission = object.favoriteShowTransmission;
    
    self.imageURL = [object favoriteImageURLForDimension:SRGImageDimensionWidth withValue:FavoriteBackupImageWidth];
    self.imageTitle = object.favoriteImageTitle;
    self.imageCopyright = object.favoriteImageCopyright;
}

#pragma mark Getters

- (SRGBlockingReason)blockingReasonAtDate:(NSDate *)date;
{
    if (self.type == FavoriteTypeMedia) {
        if ([self.object isKindOfClass:SRGMedia.class]) {
            SRGMedia *media = (SRGMedia *)self.object;
            return [media blockingReasonAtDate:date];
        }
        else {
            if (self.endDate && [self.endDate compare:date] == NSOrderedAscending) {
                return SRGBlockingReasonEndDate;
            }
            else if (self.startDate && [date compare:self.startDate] == NSOrderedAscending) {
                return SRGBlockingReasonStartDate;
            }
            else {
                return SRGBlockingReasonNone;
            }
        }
    }
    else {
        return SRGBlockingReasonNone;
    }
}

- (SRGTimeAvailability)timeAvailabilityAtDate:(NSDate *)date
{
    if (self.type == FavoriteTypeMedia) {
        if (self.endDate && [self.endDate compare:date] == NSOrderedAscending) {
            return SRGTimeAvailabilityNotAvailableAnymore;
        }
        else if (self.startDate && [date compare:self.startDate] == NSOrderedAscending) {
            return SRGTimeAvailabilityNotYetAvailable;
        }
        else {
            return SRGTimeAvailabilityAvailable;
        }
    }
    else {
        return SRGTimeAvailabilityAvailable;
    }
}

- (NSDictionary *)backupDictionary
{
    // Don't set NSNull object in the dictionary, for a plist serialization
    NSMutableDictionary *backupDictionary = [NSMutableDictionary dictionary];
    if (self.creationDate)
        backupDictionary[@"creationDate"] = self.creationDate;
    if (self.identifier)
        backupDictionary[@"favoriteIdentifier"] = self.identifier;
    
    backupDictionary[@"type"]  = @(self.type);
    if (self.uid)
        backupDictionary[@"uid"] = self.uid;
    if (self.title)
        backupDictionary[@"title"] = self.title;
    
    backupDictionary[@"mediaType"] = @(self.mediaType);
    if (self.mediaURN)
        backupDictionary[@"mediaURN"] = self.mediaURN;
    backupDictionary[@"mediaContentType"] = @(self.mediaContentType);
    if (self.date)
        backupDictionary[@"date"] = self.date;
    backupDictionary[@"duration"] = @(self.duration);
    backupDictionary[@"presentation"] = @(self.presentation);
    if (self.showTitle)
        backupDictionary[@"showTitle"] = self.showTitle;
    if (self.startDate)
        backupDictionary[@"startDate"] = self.startDate;
    if (self.endDate)
        backupDictionary[@"endDate"] = self.endDate;
    
    if (self.showURN)
        backupDictionary[@"showURN"] = self.showURN;
    backupDictionary[@"showTransmission"] = @(self.showTransmission);
    
    if (self.imageURL.absoluteString)
        backupDictionary[@"imageURL"] = self.imageURL.absoluteString;
    if (self.imageTitle)
        backupDictionary[@"imageTitle"] = self.imageTitle;
    if (self.imageCopyright)
        backupDictionary[@"imageCopyright"] = self.imageCopyright;
    
    return backupDictionary.copy;
}

- (SRGRequest *)objectForType:(FavoriteType)type available:(BOOL *)pAvailable withCompletionBlock:(void (^)(id _Nullable, NSError * _Nullable))completionBlock
{
    if (type != FavoriteTypeUnspecified && type != self.type) {
        if (pAvailable) {
            *pAvailable = NO;
        }
        return nil;
    }
    
    if (self.object) {
        if (pAvailable) {
            *pAvailable = YES;
        }
        completionBlock(self.object, nil);
        return nil;
    }
    
    // Load a missing show object
    SRGRequest *request = nil;
    if (self.type == FavoriteTypeShow) {
        SRGShowCompletionBlock showCompletionBlock = ^(SRGShow * _Nullable show, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            if (error) {
                completionBlock(nil, error);
                return;
            }
            
            [self updateWithObject:show];
            [DeprecatedFavorite saveFavoritesDictionary];
            
            completionBlock(show, nil);
        };
        
        if (self.showURN) {
            request = [SRGDataProvider.currentDataProvider showWithURN:self.showURN completionBlock:showCompletionBlock];
        }
    }
    // Load a missing video/audio object
    else if (self.type == FavoriteTypeMedia) {
        SRGMediaCompletionBlock mediaCompletionBlock = ^(SRGMedia * _Nullable media, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            if (error) {
                Download *download = [Download downloadForURN:self.mediaURN];
                if (download.media) {
                    completionBlock(download.media, nil);
                }
                else {
                    completionBlock(nil, error);
                }
                return;
            }
            
            if ([self.uid isEqualToString:media.uid]) {
                [self updateWithObject:media];
            }
            
            [DeprecatedFavorite saveFavoritesDictionary];
            
            completionBlock(self.object, nil);
        };
        
        if (self.mediaURN) {
            request = [SRGDataProvider.currentDataProvider mediaWithURN:self.mediaURN completionBlock:mediaCompletionBlock];
        }
    }
    
    if (pAvailable) {
        *pAvailable = NO;
    }
    
    [request resume];
    return request;
}

#pragma mark SRGImageMetadata protocol

- (NSURL *)imageURLForDimension:(SRGImageDimension)dimension withValue:(CGFloat)value type:(NSString *)type
{
    return self.object ? [self.object favoriteImageURLForDimension:dimension withValue:value] : _imageURL;
}

- (NSString *)imageTitle
{
    // Not saved in favorites
    return nil;
}

- (NSString *)imageCopyright
{
    // Not saved in favorites
    return nil;
}

#pragma mark Migration

+ (NSArray<DeprecatedFavorite *> *)mediaFavorites
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(DeprecatedFavorite.new, type), @(FavoriteTypeMedia)];
    NSArray<DeprecatedFavorite *> *favorites = [self.favorites filteredArrayUsingPredicate:predicate];
    return favorites.reverseObjectEnumerator.allObjects;
}

+ (NSArray<DeprecatedFavorite *> *)showFavorites
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(DeprecatedFavorite.new, type), @(FavoriteTypeShow)];
    NSArray<DeprecatedFavorite *> *favorites = [self.favorites filteredArrayUsingPredicate:predicate];
    return favorites.reverseObjectEnumerator.allObjects;
}

+ (void)finishMigrationForFavorites:(NSArray<DeprecatedFavorite *> *)favorites
{
    [favorites enumerateObjectsUsingBlock:^(DeprecatedFavorite * _Nonnull favorite, NSUInteger idx, BOOL * _Nonnull stop) {
        [s_favoritesDictionary removeObjectForKey:favorite.identifier];
    }];
    s_sortedFavorites = nil;            // Invalidate sorted favorite cache
    
    [self saveFavoritesDictionary];
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; favoriteIdentifer = %@, object = %@; creationDate = %@>",
            self.class,
            self,
            self.identifier,
            self.object,
            self.creationDate];
}

@end

#pragma mark Favoriting protocol implementation

@implementation SRGMedia (FavoriteSupport)

- (NSString *)favoriteIdentifier
{
    return FavoriteIdentifier(self.favoriteType, self.uid);
}

- (FavoriteType)favoriteType
{
    return FavoriteTypeMedia;
}

- (NSString *)favoriteUid
{
    return self.uid;
}

- (NSString *)favoriteTitle
{
    return self.title;
}

- (FavoriteMediaType)favoriteMediaType
{
    static NSDictionary<NSNumber *, NSNumber *> *s_mediaTypes;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_mediaTypes = @{ @(SRGMediaTypeVideo) : @(FavoriteMediaTypeVideo),
                          @(SRGMediaTypeAudio) : @(FavoriteMediaTypeAudio) };
    });
    return [s_mediaTypes[@(self.mediaType)] integerValue];
}


- (NSString *)favoriteMediaURN
{
    return self.URN;
}

- (FavoriteMediaContentType)favoriteMediaContentType
{
    static NSDictionary<NSNumber *, NSNumber *> *s_mediaContentTypes;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_mediaContentTypes = @{ @(SRGContentTypeLivestream) : @(FavoriteMediaContentTypeLive),
                                 @(SRGContentTypeScheduledLivestream) : @(FavoriteMediaContentTypeScheduledLive),
                                 @(SRGContentTypeEpisode) : @(FavoriteMediaContentTypeOnDemand),
                                 @(SRGContentTypeExtract) : @(FavoriteMediaContentTypeOnDemand),
                                 @(SRGContentTypeTrailer) : @(FavoriteMediaContentTypeOnDemand),
                                 @(SRGContentTypeClip) : @(FavoriteMediaContentTypeOnDemand) };
    });
    return [s_mediaContentTypes[@(self.contentType)] integerValue];
}

- (NSDate *)favoriteDate
{
    NSDate *date = nil;
    switch (self.contentType) {
        case SRGContentTypeLivestream:
            break;
        default:
            date = self.date;
            break;
    }
    return date;
}

- (NSTimeInterval)favoriteDuration
{
    NSTimeInterval duration = 0;
    switch (self.contentType) {
        case SRGContentTypeLivestream:
            duration = 0;
            break;
        default:
            duration = self.duration;
            break;
    }
    return duration;
}

- (SRGPresentation)favoritePresentation
{
    return self.presentation;
}

- (NSString *)favoriteShowTitle
{
    return self.show.title;
}

- (NSDate *)favoriteStartDate
{
    return self.startDate;
}

- (NSDate *)favoriteEndDate
{
    return self.endDate;
}

- (SRGYouthProtectionColor)favoriteYouthProtectionColor
{
    return self.youthProtectionColor;
}

- (NSString *)favoriteShowURN
{
    return nil;
}

- (FavoriteShowTransmission)favoriteShowTransmission
{
    return FavoriteShowTransmissionUnknown;
}

- (NSURL *)favoriteImageURLForDimension:(SRGImageDimension)dimension withValue:(CGFloat)value
{
    return [self imageURLForDimension:dimension withValue:value type:SRGImageTypeDefault];
}

- (NSString *)favoriteImageTitle
{
    return self.imageTitle;
}

- (NSString *)favoriteImageCopyright
{
    return self.imageCopyright;
}

@end

@implementation SRGShow (FavoriteSupport)

- (NSString *)favoriteIdentifier
{
    return FavoriteIdentifier(self.favoriteType, self.uid);
}

- (FavoriteType)favoriteType
{
    return FavoriteTypeShow;
}

- (NSString *)favoriteUid
{
    return self.uid;
}

- (NSString *)favoriteTitle
{
    return self.title;
}

- (FavoriteMediaType)favoriteMediaType
{
    return FavoriteMediaTypeUnknown;
}

- (NSString *)favoriteMediaURN
{
    return nil;
}

- (FavoriteMediaContentType)favoriteMediaContentType
{
    return FavoriteMediaContentTypeUnknown;
}

- (NSDate *)favoriteDate
{
    return nil;
}

- (NSTimeInterval)favoriteDuration
{
    return 0;
}

- (SRGPresentation)favoritePresentation
{
    return SRGPresentationNone;
}

- (NSString *)favoriteShowTitle
{
    return nil;
}

- (NSDate *)favoriteStartDate
{
    return nil;
}

- (NSDate *)favoriteEndDate
{
    return nil;
}

- (SRGYouthProtectionColor)favoriteYouthProtectionColor
{
    return SRGYouthProtectionColorNone;
}

- (NSString *)favoriteShowURN
{
    return self.URN;
}

- (FavoriteShowTransmission)favoriteShowTransmission
{
    static NSDictionary<NSNumber *, NSNumber *> *s_transmissions;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transmissions = @{ @(SRGTransmissionTV) : @(FavoriteShowTransmissionTV),
                             @(SRGTransmissionRadio) : @(FavoriteShowTransmissionRadio),
                             @(SRGTransmissionOnline) : @(FavoriteShowTransmissionOnline) };
    });
    return [s_transmissions[@(self.transmission)] integerValue];
}

- (NSURL *)favoriteImageURLForDimension:(SRGImageDimension)dimension withValue:(CGFloat)value
{
    return [self imageURLForDimension:dimension withValue:value type:SRGImageTypeDefault];
}

- (NSString *)favoriteImageTitle
{
    return self.imageTitle;
}

- (NSString *)favoriteImageCopyright
{
    return self.imageCopyright;
}

@end

static NSString *FavoriteIdentifier(FavoriteType type, NSString *uid)
{
    if (! uid) {
        return nil;
    }
    
    static NSDictionary<NSNumber *, NSString *> *s_typeNames;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_typeNames = @{ @(FavoriteTypeMedia) : @"MEDIA",
                         @(FavoriteTypeShow) : @"SHOW" };
    });
    
    NSString *typeName = s_typeNames[@(type)];
    if (! typeName) {
        return nil;
    }
    
    return [NSString stringWithFormat:@"%@_%@", typeName, uid];
}

__attribute__((constructor)) static void FavoriteInit(void)
{
    /**
     *  Favorites are saved with AutoCoding in the "favoritesFilePath" file. A corrupt file or a model update can break the
     *  favorite restoration. In such cases,the initializer tries to load the "favoritesBackupFilePath" file, which is a simple
     *  plist file without the related object. It then creates a light favorite object with just the information needed to display it.
     */
    @try {
        s_favoritesDictionary = [[DeprecatedFavorite loadFavoritesDictionary] mutableCopy];
    }
    @catch (NSException *exception) {
        PlayLogWarning(@"favorite", @"Download migration failed. Use backup dictionary instead");
    }
    
    // If model objects changed, or the plist file is corrupt, we try to load lazy favorites from the backup file.
    if (s_favoritesDictionary.count == 0) {
        NSDictionary *backupFavorite = [DeprecatedFavorite loadFavoritesBackupDictionary];
        if (backupFavorite.count > 0) {
            s_favoritesDictionary = [backupFavorite mutableCopy];
            [DeprecatedFavorite saveFavoritesDictionary];
        }
    }
    
    // If no backups, start an empty favorite list
    if (! s_favoritesDictionary) {
        s_favoritesDictionary = [NSMutableDictionary dictionary];
    }
}
