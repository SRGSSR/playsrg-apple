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
        
        tabBarsQuery.buttons["Videos"].tap()
        snapshot("1-VideosHomeScreen")
        
        tabBarsQuery.buttons["Audios"].tap()
        snapshot("2-AudiosHomeScreen")
        
        tabBarsQuery.buttons["Live"].tap()
        snapshot("3-LiveHomeScreen")
    }
}
