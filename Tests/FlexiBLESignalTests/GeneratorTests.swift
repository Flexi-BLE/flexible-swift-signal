//
//  GeneratorTests.swift
//  
//
//  Created by Blaine Rothrock on 10/17/22.
//

import XCTest
import Accelerate
@testable import FlexiBLESignal

final class GeneratorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSinWave() throws {
        let sig = SinWaveGenerator(freq: 10.0)
        sig.next(100)
        
        let mean = Int(vDSP.mean(sig.ts.col(at: 0)) * 100)
        XCTAssertEqual(mean, 0)
        
        let max = vDSP.maximum(sig.ts.col(at: 0))
        XCTAssertLessThanOrEqual(max, 1.0)
        
        let min = vDSP.minimum(sig.ts.col(at: 0))
        XCTAssertGreaterThanOrEqual(min, -1.0)
    }
    
    func testGaussianNoise() throws {
        let signal = SinWaveGenerator(freq: 10.0)
        signal.next(1000)
        let noise = GaussianNoiseGenerator(mean: 0.0, std: 1.0, step: 0.1)
        noise.next(1000)
        signal.ts.apply(colIdx: 0, vec: noise.ts.col(at: 0), op: .add)
        
        let agg = signal.ts.col(at: 1)
        
        let mean = Int(vDSP.mean(agg) * 100)
        XCTAssertEqual(mean, 0)
    }

    func testPerformanceExample() throws {
        self.measure {
            for _ in 0...10 {
                let sig = SinWaveGenerator(step: 0.1, freq: 10.0)
                sig.next(1000)
            }
        }
    }
}
