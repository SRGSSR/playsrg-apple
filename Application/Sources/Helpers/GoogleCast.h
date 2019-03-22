//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <GoogleCast/GoogleCast.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return `YES` iff Google Cast is possible for the specified media composition.
 */
OBJC_EXPORT BOOL GoogleCastIsPossible(SRGMediaComposition *mediaComposition, NSError * _Nullable __autoreleasing * _Nullable pError);

NS_ASSUME_NONNULL_END
