//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import XCTest

class ApplicationScreenshots: XCTestCase {

    override func setUp() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        continueAfterFailure = false
        
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        }
        else {
            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        }
    }
    
    override func tearDown() {
    }
    
    func testSnapshots() {
        let tabBarsQuery = XCUIApplication().tabBars
        
        let videosTabBarItemQuery = tabBarsQuery.buttons["videosTabBarItem"]
        if videosTabBarItemQuery.exists {
            videosTabBarItemQuery.tap()
            snapshot("1-VideosHomeScreen")
        }
        
        let audiosTabBarItemQuery =  tabBarsQuery.buttons["audiosTabBarItem"]
        if  audiosTabBarItemQuery.exists {
            audiosTabBarItemQuery.tap()
            snapshot("2-AudiosHomeScreen")
        }
        
        let livestreamsTabBarItemQuery =  tabBarsQuery.buttons["livestreamsTabBarItem"]
        if  livestreamsTabBarItemQuery.exists {
            livestreamsTabBarItemQuery.tap()
            snapshot("3-LiveHomeScreen")
        }
    }
}
