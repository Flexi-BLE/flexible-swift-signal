//
//  TSSignalTests.swift
//  
//
//  Created by Blaine Rothrock on 10/17/22.
//

import XCTest
import Accelerate
import Collections
@testable import flexiBLE_signal

final class TimeSeriesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitializeRange() throws {
        let start: Date = Date.now.addingTimeInterval(-60)
        let end: Date = Date.now
        let step = 1.0
        let ts = TimeSeries(with: start...end, step: step, fill: Float(0.0))
        
        XCTAssertEqual(ts.count, 60)
        XCTAssertEqual(ts.vecs.count, 1)
        XCTAssertEqual(ts.col(at: 0).reduce(0, +), 0)
        XCTAssertEqual(ts.frequency(), 1.0)
        XCTAssertEqual(ts.index.first ?? 0.0, start.timeIntervalSince1970)
        XCTAssertEqual(
            Int((ts.index.last ?? 0.0)),
            Int(end.timeIntervalSince1970 - step))
    }
    
    func testOddRange() throws {
        let length: TimeInterval = 27.49 // seconds
        let step: Double = 0.7 // seconds
        
        let start: Date = Date.now.addingTimeInterval(-length)
        let end: Date = Date.now
        let ts = TimeSeries(with: start...end, step: 0.7, fill: Float(1.0))
        
        XCTAssertEqual(ts.count, Int(length / step))
        XCTAssertEqual(ts.vecs.count, 1)
        XCTAssertEqual(ts.col(at: 0).reduce(0, +), Float(ts.count))
        XCTAssertEqual(Int(ts.frequency() * 100), Int(step * 100))
    }

    func testLimitingPersistence() throws {
        var ts: TimeSeries<Float> = TimeSeries(persistence: 100)

        for i in 0...99 {
            ts.add(date: Date.now.addingTimeInterval(Double(i)), values: [1.0])
        }

        XCTAssertEqual(ts.count, 100)
        var lastDate = Date.now.addingTimeInterval(100)
        var secondDate = ts.index[1]

        ts.add(date: lastDate, values: [1.0]) // overflow

        XCTAssertEqual(ts.count, 100)
        XCTAssertEqual(ts.index[0], secondDate)
        XCTAssertEqual(ts.index.last, lastDate.timeIntervalSince1970)
        XCTAssertEqual(Int(ts.frequency() * 100), 100)
    }

    func testRangeInitialationTime() throws {
        self.measure {
            for _ in 0..<10 {
                let _ = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 0.01)
            }
        }
    }
    
    func testRangeFrequencyCalculation() throws {
        let ts = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 0.01)
        
        self.measure {
            for _ in 0..<10 {
                let _ = ts.frequency()
            }
        }
    }
    
    func testDSPRamp() throws {
        self.measure {
            for _ in 0...10 {
                let _ = vDSP.ramp(
                    withInitialValue: Date.now.timeIntervalSince1970,
                    increment: 0.01,
                    count: 1_000_000
                )
            }
        }
    }

}
