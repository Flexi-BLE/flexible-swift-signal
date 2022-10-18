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
        XCTAssertEqual(ts.colCount, 1)
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
        XCTAssertEqual(ts.colCount, 1)
        XCTAssertEqual(ts.col(at: 0).reduce(0, +), Float(ts.count))
        XCTAssertEqual(Int(ts.frequency() * 100), Int(step * 100))
    }

    func testLimitingPersistence() throws {
        var ts: TimeSeries<Float> = TimeSeries(persistence: 100)

        for i in 0...99 {
            ts.add(date: Date.now.addingTimeInterval(Double(i)), values: [1.0])
        }

        XCTAssertEqual(ts.count, 100)
        let lastDate = Date.now.addingTimeInterval(100)
        let secondDate = ts.index[1]

        ts.add(date: lastDate, values: [1.0]) // overflow

        XCTAssertEqual(ts.count, 100)
        XCTAssertEqual(ts.index[0], secondDate)
        XCTAssertEqual(ts.index.last, lastDate.timeIntervalSince1970)
        XCTAssertEqual(Int(ts.frequency() * 100), 100)
    }

    func testSorting() throws {
        var unsortedTS = TimeSeries<Float>(persistence: 500)
        for i in 0...99 {
            unsortedTS.add(epoch: Double(i), values: [0, Float(i*1)])
            unsortedTS.add(epoch: Double(i)+0.1, values: [1, Float(i*2)])
            unsortedTS.add(epoch: Double(i)+0.2, values: [2, Float(i*3)])
        }

        let sortedTss = unsortedTS.splitSort(
            criteria: [
                    TimeSeriesSortCondition<Float>(colIdx: 0, filter: { $0 == 0 }, include: [0, 1]),
                    TimeSeriesSortCondition<Float>(colIdx: 0, filter: { $0 == 1 }, include: [0, 1]),
                    TimeSeriesSortCondition<Float>(colIdx: 0, filter: { $0 == 2 }, include: [0, 1])
                ]
        )

        let cat1 = sortedTss[0]
        let cat2 = sortedTss[1]
        let cat3 = sortedTss[2]
        XCTAssertEqual(cat1.count, 100)
        XCTAssertEqual(cat2.count, 100)
        XCTAssertEqual(cat3.count, 100)

        XCTAssertEqual(Set(cat1.col(at: 0)), Set<Float>([Float(0.0)]))
        XCTAssertEqual(Set(cat2.col(at: 0)), Set<Float>([Float(1.0)]))
        XCTAssertEqual(Set(cat3.col(at: 0)), Set<Float>([Float(2.0)]))
    }

    func testColumnNames() throws {
        var ts = TimeSeries<Float>(persistence: 500)
        for i in 0...99 {
            ts.add(epoch: Double(i), values: [0, Float(1)])
            ts.add(epoch: Double(i) + 0.1, values: [1, Float(2)])
            ts.add(epoch: Double(i) + 0.2, values: [2, Float(3)])
        }

        XCTAssertEqual(ts.col(with: "1").count, 300)
        XCTAssertEqual(ts.col(with: "2").count, 300)

        ts.setColNames(["one", "two"])
        XCTAssertEqual(ts.col(with: "one").count, 300)
        XCTAssertEqual(ts.col(with: "two").count, 300)
    }

    func testPurge() throws {
        var ts = TimeSeries<Float>(persistence: 500)
        let startDate = Date.now
        for i in 0...99 {
            ts.add(date: startDate.addingTimeInterval(Double(i)), values: [Float(i)])
        }

        ts.purge(before: startDate.addingTimeInterval(50))
        XCTAssertEqual(ts.index.first!, startDate.addingTimeInterval(50).timeIntervalSince1970)
    }

    func testSortingPerformance() throws {
        var unsortedTS = TimeSeries<Float>(persistence: 3000)
        for i in 0...1000 {
            unsortedTS.add(epoch: Double(i), values: [0, Float(i*1)])
            unsortedTS.add(epoch: Double(i)+0.1, values: [1, Float(i*2)])
            unsortedTS.add(epoch: Double(i)+0.2, values: [2, Float(i*3)])
        }

        self.measure {
            let _ = unsortedTS.splitSort(
                    criteria: [
                        TimeSeriesSortCondition(colIdx: 0, filter: { $0 == 0 }, include: [1]),
                        TimeSeriesSortCondition(colIdx: 0, filter: { $0 == 1 }, include: [1]),
                        TimeSeriesSortCondition(colIdx: 0, filter: { $0 == 2 }, include: [1])
                    ]
            )
        }
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
