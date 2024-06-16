//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//
import Foundation

@objc enum AccessibilityIdentifier: UInt {
    case videosTabBarItem
    case audiosTabBarItem
    case livestreamsTabBarItem
    case tvGuideTabBarItem
    case showsTabBarItem
    case searchTabBarItem
    case profileTabBarItem
    case closeButton

    var value: String {
        switch self {
        case .videosTabBarItem:
            return "videosTabBarItem"
        case .audiosTabBarItem:
            return "audiosTabBarItem"
        case .livestreamsTabBarItem:
            return "livestreamsTabBarItem"
        case .tvGuideTabBarItem:
            return "tvGuideTabBarItem"
        case .showsTabBarItem:
            return "showsTabBarItem"
        case .searchTabBarItem:
            return "searchTabBarItem"
        case .profileTabBarItem:
            return "profileTabBarItem"
        case .closeButton:
            return "closeButton"
        }
    }
}

/**
 *  Accessibility identifier compatibility for Objective-C, as a class.
 */
@objc class AccessibilityIdentifierObjC: NSObject {
    private let identifier: AccessibilityIdentifier

    @objc class func identifier(_ identifier: AccessibilityIdentifier) -> AccessibilityIdentifierObjC {
        return Self(identifier: identifier)
    }

    @objc var value: String {
        return identifier.value
    }

    required init(identifier: AccessibilityIdentifier) {
        self.identifier = identifier
    }
}
