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
        
        tabBarsQuery.buttons["videosTabBarItem"].tap()
        snapshot("1-VideosHomeScreen")
        
        tabBarsQuery.buttons["audiosTabBarItem"].tap()
        snapshot("2-AudiosHomeScreen")
        
        tabBarsQuery.buttons["livestreamsTabBarItem"].tap()
        snapshot("3-LiveHomeScreen")
    }
}
