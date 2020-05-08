//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Channel.h"

#import <SRGAppearance/SRGAppearance.h>

@interface Channel ()

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *resourceUid;
@property (nonatomic) UIColor *color;
@property (nonatomic) UIColor *titleColor;
@property (nonatomic) UIColor *gradientStartColor;
@property (nonatomic) UIColor *gradientEndColor;
@property (nonatomic, getter=hasDarkStatusBar) BOOL darkStatusBar;

@end

@implementation Channel

#pragma mark Object lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.uid = dictionary[@"uid"];
        if (! [self.uid isKindOfClass:NSString.class]) {
            return nil;
        }
        
        self.name = dictionary[@"name"];
        if (! [self.name isKindOfClass:NSString.class]) {
            return nil;
        }
        
        self.resourceUid = dictionary[@"resourceUid"];
        if (! [self.resourceUid isKindOfClass:NSString.class]) {
            return nil;
        }
        
        id colorValue = dictionary[@"color"];
        if ([colorValue isKindOfClass:NSString.class]) {
            self.color = [UIColor srg_colorFromHexadecimalString:colorValue] ?: UIColor.grayColor;
        }
        else {
            self.color = UIColor.grayColor;
        }
        
        id titleColorValue = dictionary[@"titleColor"];
        if ([titleColorValue isKindOfClass:NSString.class]) {
            self.titleColor = [UIColor srg_colorFromHexadecimalString:titleColorValue] ?: UIColor.whiteColor;
        }
        else {
            self.titleColor = UIColor.whiteColor;
        }
        
        id gradientStartColorValue = dictionary[@"gradientStartColor"];
        if ([gradientStartColorValue isKindOfClass:NSString.class]) {
            self.gradientStartColor = [UIColor srg_colorFromHexadecimalString:gradientStartColorValue] ?: self.color;
        }
        else {
            self.gradientStartColor = self.color;
        }
        
        id gradientEndColorValue = dictionary[@"gradientEndColor"];
        if ([gradientEndColorValue isKindOfClass:NSString.class]) {
            self.gradientEndColor = [UIColor srg_colorFromHexadecimalString:gradientEndColorValue] ?: self.gradientStartColor;
        }
        else {
            self.gradientEndColor = self.gradientStartColor;
        }
        
        id darkStatusBarValue = dictionary[@"hasDarkStatusBar"];
        if ([darkStatusBarValue isKindOfClass:NSNumber.class]) {
            self.darkStatusBar = [darkStatusBarValue boolValue];
        }
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithDictionary:@{}];
}

#pragma mark Object identity

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (! [object isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.uid isEqualToString:[object uid]];
}

- (NSUInteger)hash
{
    return self.uid.hash;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; uid = %@; name = %@>",
            self.class,
            self,
            self.uid,
            self.name];
}

@end
