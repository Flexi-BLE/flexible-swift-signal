//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 10/17/22.
//

import Foundation
import Accelerate

class TimeSeriesGenerator<T: FXBFloatingPoint> {
    internal var kernel: (Double)->T
    
    var ts: TimeSeries<T>
    var cursor: Double
    var step: Double
    
    init(step: Double=1.0, start: Date?=nil, kernel: @escaping (Double) -> T) {
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
        phase p: Float = 0.0,
        step: Double = 1.0,
        start: Date? = nil
    
    ) -> TimeSeriesGenerator<Float> {
        
        return TimeSeriesGenerator(step: step, start: start) { i in
            A * sin(Float(i) + p)
        }
    }
    
    static func gaussianNoise(
        mean: Float = 0.0,
        std: Float = 1.0,
        step: Double = 1.0,
        start: Date? = nil
    
    ) -> TimeSeriesGenerator<Float> {
        
        return GaussianTimeSeriesGenerator(
            mean: mean,
            std: std,
            step: step,
            start: start
        )
    }
}
