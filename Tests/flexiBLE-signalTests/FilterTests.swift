//
// Created by Blaine Rothrock on 10/18/22.
//

import XCTest
import Accelerate
@testable import flexiBLE_signal

final class vDSPTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMinMaxScaling() throws {
        let amplitude: Float = 1.0
        let freq: Float = 10.0
        let phase: Float = 0.0
        let sig = TimeSeriesFactory.sinWave(amplitude: amplitude, freq: freq, phase: phase)
        sig.next(1_000)

        let factor: Float = 10.0
        sig.ts.apply(colIdx: 0, vec: [Float](repeating: factor, count: sig.ts.count), op: .add)
        sig.ts.apply(filter: .minMaxScaling, to: 1)

        XCTAssertEqual(Int(vDSP.mean(sig.ts.col(at: 1)) * 100), Int(factor * 100))
    }

    func testZScore() throws {
        let amplitude: Float = 1.0
        let freq: Float = 10.0
        let phase: Float = 0.0
        let sig = TimeSeriesFactory.sinWave(amplitude: amplitude, freq: freq, phase: phase)
        sig.next(1_000)

        let factor: Float = 10.0
        sig.ts.apply(colIdx: 0, vec: [Float](repeating: factor, count: sig.ts.count), op: .add)
        sig.ts.apply(filter: .zscore, to: 1)

        XCTAssertEqual(Int(vDSP.mean(sig.ts.col(at: 1)) * 100), Int(factor * 100))
    }

    func testMovingAverage() throws {
        let amplitude: Float = 1.0
        let freq: Float = 10.0
        let phase: Float = 0.0
        let sig = TimeSeriesFactory.sinWave(amplitude: amplitude, freq: freq, phase: phase)
        sig.next(1_000)

        let noise = TimeSeriesFactory.gaussianNoise(mean: 0.0, std: 1.0, step: 0.1)
        noise.next(1_000)
        sig.ts.apply(colIdx: 0, vec: noise.ts.col(at: 0), op: .add)

        sig.ts.apply(filter: TimeSeries.FilterType.movingAverage(window: 10), to: 1)

        XCTAssertEqual(Int(vDSP.mean(sig.ts.col(at: 2)) * 100), Int(vDSP.mean(sig.ts.col(at: 1)) * 100))
        XCTAssertLessThan(vDSP.maximum(sig.ts.col(at: 2)), vDSP.maximum(sig.ts.col(at: 1)))
        XCTAssertGreaterThan(vDSP.minimum(sig.ts.col(at: 2)), vDSP.minimum(sig.ts.col(at: 1)))
    }

    func testNegAddition() throws {
        var x = [Float](repeating: 0.0, count: 100)
        vDSP.add(-10.0, x, result: &x)

        print()
    }

    func testMinMaxPerformance() throws {
        self.measure {
            for _ in 0..<10 {
                var ts = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 1.0)
                ts.apply(filter: .minMaxScaling, to: 0)
            }
        }
    }

    func testDemeanPerformance() throws {
        self.measure {
            for _ in 0..<10 {
                var ts = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 1.0)
                ts.apply(filter: .demean, to: 0)
            }
        }
    }

    func testZscorePerformance() throws {
        self.measure {
            for _ in 0..<10 {
                var ts = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 1.0)
                ts.apply(filter: .zscore, to: 0)
            }
        }
    }

    func testMovingAveragePerformance() throws {
        self.measure {
            for _ in 0..<10 {
                var ts = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 1.0)
                ts.apply(filter: .movingAverage(window: 50), to: 0)
            }
        }
    }

    func testStdPerformance() throws {
        self.measure {
            for _ in 0..<10 {
                let _ = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 0.01)
            }
        }
    }
}
