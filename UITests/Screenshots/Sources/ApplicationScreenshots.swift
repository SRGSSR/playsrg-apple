//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import XCTest

class ApplicationScreenshots: XCTestCase {
    
    var configuration: NSDictionary = [:]
    
    override func setUp() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        continueAfterFailure = false
        
        if (UIDevice.current.userInterfaceIdiom == .pad) {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        else {
            XCUIDevice.shared.orientation = .portrait
        }
        
        let testBundle = Bundle(for: type(of: self))
        if let path = testBundle.path(forResource: "Configuration", ofType: "plist") {
            configuration = NSDictionary(contentsOfFile: path) ?? [:]
        }
    }
    
    func testSnapshots() {
        let application = XCUIApplication()
        
        let tabBarsQuery = application.tabBars
        
        let videosTabBarItemQuery = tabBarsQuery.buttons[AccessibilityIdentifier.videosTabBarItem.rawValue]
        if videosTabBarItemQuery.exists {
            videosTabBarItemQuery.tap()
            
            sleep(10)
            snapshot("1-VideosHomeScreen")
        }
        
        let audiosTabBarItemQuery = tabBarsQuery.buttons[AccessibilityIdentifier.audiosTabBarItem.rawValue]
        if audiosTabBarItemQuery.exists {
            audiosTabBarItemQuery.tap()
            
            sleep(10)
            snapshot("2-AudiosHomeScreen")
        }
        
        let livestreamsTabBarItemQuery = tabBarsQuery.buttons[AccessibilityIdentifier.livestreamsTabBarItem.rawValue]
        if livestreamsTabBarItemQuery.exists {
            livestreamsTabBarItemQuery.tap()
            
            sleep(10)
            snapshot("3-LiveHomeScreen")
            
            let firstRadioCellQuery = application.tables.firstMatch.cells.element(boundBy: 1).collectionViews.cells.firstMatch
            if firstRadioCellQuery.exists {
                firstRadioCellQuery.tap()
                
                sleep(10)
                snapshot("4-RadioLivePlayer")
                
                let closeButtonQuery = application.buttons[AccessibilityIdentifier.closeButton.rawValue];
                if closeButtonQuery.exists {
                    closeButtonQuery.tap()
                }
            }
        }
        
        let searchText = configuration["SearchText"]
        let searchTabBarItemQuery = tabBarsQuery.buttons[AccessibilityIdentifier.searchTabBarItem.rawValue]
        if searchTabBarItemQuery.exists && searchText != nil {
            searchTabBarItemQuery.tap()
            
            let searchTextField = application.searchFields.firstMatch
            searchTextField.tap()
            searchTextField.typeText(searchText as! String)
            application.typeText("\n")
            
            sleep(10)
            snapshot("5-SearchScreen")
        }
    }
}
