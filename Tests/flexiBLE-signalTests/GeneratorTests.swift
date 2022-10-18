//
//  GeneratorTests.swift
//  
//
//  Created by Blaine Rothrock on 10/17/22.
//

import XCTest
@testable import flexiBLE_signal

final class GeneratorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSinWave() throws {
        let sig = TimeSeriesFactory.sinWave(amplitude: 1.0, freq: 10.0, phase: 0.0)
        sig.next(100)
        
        print(sig.ts)
    }

    func testPerformanceExample() throws {
        let sig = TimeSeriesFactory.sinWave(amplitude: 1.0, freq: 10.0, phase: 0.0)
        self.measure {
            for _ in 0...10 {
                sig.next(1000)
            }
        }
    }

}
