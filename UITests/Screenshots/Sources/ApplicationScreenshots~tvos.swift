//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import XCTest

class ApplicationScreenshots: XCTestCase {
    static let configuration: NSDictionary = {
        if let path = Bundle(for: ApplicationScreenshots.self).path(forResource: "Configuration", ofType: "plist") {
            return NSDictionary(contentsOfFile: path) ?? [:]
        }
        else {
            return [:]
        }
    }()
    
    override func setUp() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        continueAfterFailure = false
    }
    
    func testSnapshots() {
        // Wait a bit for the focus engine to determine the first focused item
        sleep(5)
        
        // Navigate tabs with the remote and perform the action depending on the tab which is reached
        var previousIdentifier: String?
        while true {
            guard let identifier = focusedIdentifier, previousIdentifier != identifier else {
                break
            }
            previousIdentifier = identifier
            
            switch identifier {
            case AccessibilityIdentifier.videosTabBarItem.rawValue:
                sleep(10)
                snapshot("1-VideosHomeScreen")
            case AccessibilityIdentifier.livestreamsTabBarItem.rawValue:
                sleep(10)
                snapshot("2-LiveHomeScreen")
            case AccessibilityIdentifier.showsTabBarItem.rawValue:
                sleep(20)       // Need more time for some BUs
                snapshot("3-ShowsScreen")
            case AccessibilityIdentifier.searchTabBarItem.rawValue:
                if let searchText = Self.configuration["SearchText"] as? String {
                    let searchField = XCUIApplication().searchFields.firstMatch
                    searchField.typeText(searchText)
                }
                sleep(10)
                snapshot("4-SearchScreen")
            default:
                ()
            }
            
            moveToNextTabBarItem()
        }
    }
    
    var focusedIdentifier: String? {
        // String-based predicate recommended by `elements(matching:)` documentation
        let identifier = XCUIApplication().descendants(matching: .any).element(matching: NSPredicate(format: "hasFocus == true")).identifier
        return !identifier.isEmpty ? identifier : nil
    }
    
    func moveToNextTabBarItem() {
        let remote = XCUIRemote.shared
        
        // Press Menu if to return to the tab bar if needed. All our tab bar accessibility identifiers contain 'TabBarItem',
        // which allows us to test against all possible identifiers without explicitly listing them
        if let identifier = focusedIdentifier, identifier.contains("TabBarItem") {
            remote.press(.right)
        }
        else {
            remote.press(.menu)
            remote.press(.right)
        }
    }
}
