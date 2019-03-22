//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLogger/SRGLogger.h>

/**
 *  Macros for logging
 */
#define PlayLogVerbose(category, format, ...) SRGLogVerbose(@"ch.srgssr.play", category, format, ##__VA_ARGS__)
#define PlayLogDebug(category, format, ...)   SRGLogDebug(@"ch.srgssr.play", category, format, ##__VA_ARGS__)
#define PlayLogInfo(category, format, ...)    SRGLogInfo(@"ch.srgssr.play", category, format, ##__VA_ARGS__)
#define PlayLogWarning(category, format, ...) SRGLogWarning(@"ch.srgssr.play", category, format, ##__VA_ARGS__)
#define PlayLogError(category, format, ...)   SRGLogError(@"ch.srgssr.play", category, format, ##__VA_ARGS__)
