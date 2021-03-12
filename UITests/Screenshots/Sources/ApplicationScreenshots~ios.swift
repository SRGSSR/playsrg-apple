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
        
        XCUIDevice.shared.orientation = (UIDevice.current.userInterfaceIdiom == .pad) ? .landscapeLeft : .portrait
    }
    
    func testSnapshots() {
        if let videosTabBarItem = tabBarItem(withIdentifier: AccessibilityIdentifier.videosTabBarItem.rawValue) {
            videosTabBarItem.tap()
            sleep(10)
            snapshot("1-VideosHomeScreen")
        }
        
        if let audiosTabBarItem = tabBarItem(withIdentifier: AccessibilityIdentifier.audiosTabBarItem.rawValue) {
            audiosTabBarItem.tap()
            sleep(10)
            snapshot("2-AudiosHomeScreen")
        }
        
        if let livestreamsTabBarItem = tabBarItem(withIdentifier: AccessibilityIdentifier.livestreamsTabBarItem.rawValue) {
            livestreamsTabBarItem.tap()
            sleep(10)
            snapshot("3-LiveHomeScreen")
            
            if let firstRadioCell = gridCell(1, 0) {
                firstRadioCell.tap()
                sleep(10)
                snapshot("4-RadioLivePlayer")
                
                if let closeButton = button(withIdentifier: AccessibilityIdentifier.closeButton.rawValue) {
                    closeButton.tap()
                }
            }
        }
        
        if let showsTabBarItem = tabBarItem(withIdentifier: AccessibilityIdentifier.showsTabBarItem.rawValue) {
            showsTabBarItem.tap()
            sleep(10)
            snapshot("5-ShowsScreen")
        }
        
        if let searchTabBarItem = tabBarItem(withIdentifier: AccessibilityIdentifier.searchTabBarItem.rawValue),
           let searchText = Self.configuration["SearchText"] as? String {
            searchTabBarItem.tap()
            
            let searchField = XCUIApplication().searchFields.firstMatch
            searchField.tap()
            searchField.typeText("\(searchText)\n")
            
            sleep(10)
            snapshot("6-SearchScreen")
        }
    }
}

extension ApplicationScreenshots {
    func tabBarItem(withIdentifier identifier: String) -> XCUIElement? {
        let tabBarItem = XCUIApplication().tabBars.buttons[identifier]
        return tabBarItem.exists ? tabBarItem : nil
    }
    
    func button(withIdentifier identifier: String) -> XCUIElement? {
        let button = XCUIApplication().buttons[identifier]
        return button.exists ? button : nil
    }
    
    func gridCell(_ x: Int, _ y: Int) -> XCUIElement? {
        let cell = XCUIApplication().tables.firstMatch.cells.element(boundBy: x).collectionViews.cells.element(boundBy: y)
        return cell.exists ? cell : nil
    }
}
