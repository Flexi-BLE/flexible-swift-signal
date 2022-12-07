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
        let freq: Float = 10.0
        let sig = SinWaveGenerator(freq: freq)
        sig.next(1_001)

        let factor: Float = 10.0
        sig.ts.apply(colIdx: 0, vec: [Float](repeating: factor, count: sig.ts.count), op: .add)
        let filter = MinMaxScalingFilter()
        sig.ts.apply(filter: filter)

        XCTAssertEqual(Int(vDSP.mean(sig.ts.col(at: 1)) * 100), Int(factor * 100))
    }

    func testZScore() throws {
        let freq: Float = 10.0
        let sig = SinWaveGenerator(freq: freq)
        sig.next(1_001)

        let factor: Float = 10.0
        sig.ts.apply(colIdx: 0, vec: [Float](repeating: factor, count: sig.ts.count), op: .add)
        sig.ts.apply(filter: ZScoreFilter())

        XCTAssertEqual(Int(vDSP.mean(sig.ts.col(at: 1)) * 100), Int(factor * 100))
    }

    func testMovingAverage() throws {
        let sig = SinWaveGenerator(freq: 10.0)
        sig.next(1_000)

        let noise = GaussianNoiseGenerator(mean: 0.0, std: 1.0, step: 0.1)
        noise.next(1_000)
        sig.ts.apply(colIdx: 0, vec: noise.ts.col(at: 0), op: .add)

        let filter = MovingAverageFilter(window: 10)
        sig.ts.apply(filter: filter, to: 1)

        XCTAssertLessThan(vDSP.maximum(sig.ts.col(at: 2)), vDSP.maximum(sig.ts.col(at: 1)))
        XCTAssertGreaterThan(vDSP.minimum(sig.ts.col(at: 2)), vDSP.minimum(sig.ts.col(at: 1)))
    }

    func testLowPass() throws {
        let sig = CombinationSinWaveGenerator(frequencies: [1, 10, 20], step: 0.001, persistence: 6_000)
        sig.next(6_000)

        let filter = LowPassFilter(frequency: Float(sig.ts.frequency()), cutoffFrequency: 15, transitionFrequency: 2)
        sig.ts.apply(filter: filter)

        print()
    }

    func testMinMaxPerformance() throws {
        self.measure {
            for _ in 0..<10 {
                var ts = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 1.0)
                ts.apply(filter: MinMaxScalingFilter(), to: 0)
            }
        }
    }

    func testDemeanPerformance() throws {
        self.measure {
            for _ in 0..<10 {
                var ts = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 1.0)
                ts.apply(filter: DemeanFilter(), to: 0)
            }
        }
    }

    func testZscorePerformance() throws {
        self.measure {
            for _ in 0..<10 {
                var ts = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 1.0)
                ts.apply(filter: ZScoreFilter(), to: 0)
            }
        }
    }

    func testMovingAveragePerformance() throws {
        self.measure {
            for _ in 0..<10 {
                var ts = TimeSeries(with: Date.now.addingTimeInterval(-100_000)...Date.now, step: 1.0)
                ts.apply(filter: MovingAverageFilter(window: 50), to: 0)
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
