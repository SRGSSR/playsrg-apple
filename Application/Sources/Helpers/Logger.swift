//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGLoggerSwift

func PlayLogVerbose(category: String?, message: String, file: String = #file, function: String = #function, line: UInt = #line) {
    SRGLogVerbose(subsystem: "ch.srgssr.play", category: category, message: message, file: file, function: function, line: line)
}

func PlayLogDebug(category: String?, message: String, file: String = #file, function: String = #function, line: UInt = #line) {
    SRGLogDebug(subsystem: "ch.srgssr.play", category: category, message: message, file: file, function: function, line: line)
}

func PlayLogInfo(category: String?, message: String, file: String = #file, function: String = #function, line: UInt = #line) {
    SRGLogInfo(subsystem: "ch.srgssr.play", category: category, message: message, file: file, function: function, line: line)
}

func PlayLogWarning(category: String?, message: String, file: String = #file, function: String = #function, line: UInt = #line) {
    SRGLogWarning(subsystem: "ch.srgssr.play", category: category, message: message, file: file, function: function, line: line)
}

func PlayLogError(category: String?, message: String, file: String = #file, function: String = #function, line: UInt = #line) {
    SRGLogError(subsystem: "ch.srgssr.play", category: category, message: message, file: file, function: function, line: line)
}
