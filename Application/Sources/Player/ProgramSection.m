//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ProgramSection.h"

@interface ProgramSection ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSArray<SRGProgram *> *programs;
@property (nonatomic, getter=isInteractive) BOOL interactive;

@end

@implementation ProgramSection

#pragma mark Object lifecycle

- (instancetype)initWithTitle:(NSString *)title programs:(NSArray<SRGProgram *> *)programs interactive:(BOOL)interactive
{
    if (self = [super init]) {
        self.title = title;
        self.programs = programs;
        self.interactive = interactive;
    }
    return self;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; title = %@; programs = %@>",
            self.class,
            self,
            self.title,
            self.programs];
}

@end
