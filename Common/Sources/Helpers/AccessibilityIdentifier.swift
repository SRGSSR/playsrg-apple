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
            "videosTabBarItem"
        case .audiosTabBarItem:
            "audiosTabBarItem"
        case .livestreamsTabBarItem:
            "livestreamsTabBarItem"
        case .tvGuideTabBarItem:
            "tvGuideTabBarItem"
        case .showsTabBarItem:
            "showsTabBarItem"
        case .searchTabBarItem:
            "searchTabBarItem"
        case .profileTabBarItem:
            "profileTabBarItem"
        case .closeButton:
            "closeButton"
        }
    }
}

/**
 *  Accessibility identifier compatibility for Objective-C, as a class.
 */
@objc class AccessibilityIdentifierObjC: NSObject {
    private let identifier: AccessibilityIdentifier

    @objc class func identifier(_ identifier: AccessibilityIdentifier) -> AccessibilityIdentifierObjC {
        Self(identifier: identifier)
    }

    @objc var value: String {
        identifier.value
    }

    required init(identifier: AccessibilityIdentifier) {
        self.identifier = identifier
    }
}
