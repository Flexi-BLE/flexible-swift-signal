//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 10/17/22.
//

import Foundation
import Accelerate

class TimeSeriesGenerator<T: FloatingPoint> {
    internal var kernel: (Double)->T
    
    var ts: TimeSeries<T>
    var cursor: Double
    var step: Double
    
    init(kernel: @escaping (Double) -> T, step: Double=1.0, start: Date?=nil) {
        self.kernel = kernel
        self.ts = TimeSeries(persistence: 1000)
        self.cursor = start == nil ? 0.0 : start!.timeIntervalSince1970
        self.step = step
    }
    
    func next(_ count: Int = 1) {
        for _ in 0...count {
            ts.add(epoch: cursor, values: [kernel(cursor)])
            cursor += step
        }
    }
}

enum TimeSeriesFactory {
    static func sinWave(
        amplitude A: Float = 1.0,
        freq f: Float = 0.5,
        phase p: Float = 0.0
    ) -> TimeSeriesGenerator<Float> {
        
        return TimeSeriesGenerator { i in
            A * sin(Float(i) + p)
        }
    }
    
//    static func gaussianNoise(
//        mean mu: Float,
//        std sigma: Float,
//        tranmissionVec:
//    )
}
