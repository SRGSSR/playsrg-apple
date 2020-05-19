//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProgramSection : NSObject

- (instancetype)initWithTitle:(NSString *)title programs:(NSArray<SRGProgram *> *)programs interactive:(BOOL)interactive;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly) NSArray<SRGProgram *> *programs;
@property (nonatomic, readonly, getter=isInteractive) BOOL interactive;

@end

NS_ASSUME_NONNULL_END
