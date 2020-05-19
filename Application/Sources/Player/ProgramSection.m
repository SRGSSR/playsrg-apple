//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ProgramSection.h"

@interface ProgramSection ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSArray<SRGProgram *> *programs;

@end

@implementation ProgramSection

#pragma mark Object lifecycle

- (instancetype)initWithTitle:(NSString *)title programs:(NSArray<SRGProgram *> *)programs
{
    if (self = [super init]) {
        self.title = title;
        self.programs = programs;
    }
    return self;
}

@end
