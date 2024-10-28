//
//  HanaMiUITests.swift
//  HanaMiUITests
//
//  Created by Tzu ning Lo on 2024/10/23.
//

import XCTest
//@testable import HanaMi

final class HanaMiUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    func testHeartAnimationShowsAfterFavoriteButtonTap() throws {
//        // 每個測試都應該啟動應用，這樣測試是獨立的
//        let app = XCUIApplication()
//        app.launch()
//        
//        // 找到並點擊地圖標籤
//        let mapTab = app.buttons["MapTab"]
//        XCTAssertTrue(mapTab.exists, "地圖標籤應該存在")
//        mapTab.tap()
//        
//        let mapView = app.otherElements["MapView"]
//        XCTAssertTrue(mapView.exists, "地圖應該顯示")
//        
//        let treasureAnnotation = app.otherElements["TreasureAnnotation_YourTreasureID"]  // 替換 YourTreasureID 為具體寶藏的 ID
//        XCTAssertTrue(treasureAnnotation.exists, "寶藏的 annotation 應該存在")
//        treasureAnnotation.tap()
//        
//        // 找到收藏按鈕
//        let favoriteButton = app.buttons["AddToFavoriteButton"]
//        XCTAssertTrue(favoriteButton.exists, "收藏按鈕應該存在")
//        
//        // 點擊收藏按鈕
//        favoriteButton.tap()
//        
//        // 檢查愛心動畫是否顯示，並等待動畫出現
//        let heartAnimation = app.otherElements["HeartAnimation"]
//        XCTAssertTrue(heartAnimation.waitForExistence(timeout: 5), "愛心動畫應該在收藏後顯示")
//    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
