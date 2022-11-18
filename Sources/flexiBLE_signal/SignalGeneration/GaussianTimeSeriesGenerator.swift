//
//  GaussianTimeSeriesGenerator.swift
//  
//
//  Created by Blaine Rothrock on 10/18/22.
//

import Foundation
import GameKit

class GaussianNoiseGenerator: TimeSeriesGenerator {
    private let random = GKRandomSource()
    private let gen: GKGaussianDistribution

    var step: Double
    var cursor: Double
    var i: Int = 0
    var ts: TimeSeries<Float>
    
    init(mean: Float, std: Float, step: Double, start: Date?=nil) {
        self.ts = TimeSeries(persistence: 1000)
        self.cursor = start == nil ? 0.0 : start!.timeIntervalSince1970
        self.step = step
        self.gen = GKGaussianDistribution(
            randomSource: random,
            mean: mean,
            deviation: std
        )
    }
    
    func next(_ count: Int = 1) {
        for _ in 0...count {
            ts.add(epoch: cursor, values: [self.gen.nextUniform()])
            cursor += step
            i += 1
        }
    }
}
