//
//  HanaMiTests.swift
//  HanaMiTests
//
//  Created by Tzu ning Lo on 2024/10/21.
//

import XCTest
@testable import HanaMi

final class HanaMiTests: XCTestCase {
    
    var viewModel: TreasureDetailView!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
                
                let mockTreasure = Treasure(
                    id: "123",
                    category: "TestCategory",
                    createdTime: Date(),
                    isPublic: true,
                    latitude: 37.7749,
                    longitude: -122.4194,
                    locationName: "Test Location",
                    contents: [],
                    userID: "userA"
                )
                viewModel = TreasureDetailView(treasure: mockTreasure)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        viewModel = nil
        super.tearDown()
    }

        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        //測試愛心動畫的邏輯，即檢查動畫播放的狀態變化
        //isPlayingHeartAnimation 是否按預期開啟和關閉
        func testHeartAnimation_PlayAndStop() throws {
            // Arrange: 提供完整的 Treasure 參數
            viewModel.isPlayingHeartAnimation = true
            
            // Assert: 使用 DispatchQueue 確認動畫在預期時間後停止
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                XCTAssertFalse(self.viewModel.isPlayingHeartAnimation)
            }
        }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
