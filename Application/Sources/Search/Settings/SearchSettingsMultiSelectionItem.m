//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingsMultiSelectionItem.h"

@interface SearchSettingsMultiSelectionItem ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *value;
@property (nonatomic) NSUInteger count;

@end

@implementation SearchSettingsMultiSelectionItem

#pragma mark Object lifecycle

- (instancetype)initWithName:(NSString *)name value:(NSString *)value count:(NSInteger)count
{
    if (self = [super init]) {
        self.name = name;
        self.value = value;
        self.count = count;
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma clang diagnostic pop

@end
