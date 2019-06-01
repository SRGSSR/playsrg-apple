//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DeprecatedFavorite.h"

#import "ApplicationConfiguration.h"
#import "Download.h"
#import "NSDateFormatter+PlaySRG.h"
#import "PlayErrors.h"
#import "PlayLogger.h"

#import <CoconutKit/CoconutKit.h>
#import <libextobjc/libextobjc.h>
#import <SRGLogger/SRGLogger.h>

static NSString *FavoriteIdentifier(FavoriteType type, NSString *uid);

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

#pragma mark Object lifecycle

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
        PlayLogWarning(@"favorite", @"Favorite migration failed. Use backup dictionary instead");
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
