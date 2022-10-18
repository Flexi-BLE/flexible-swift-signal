//
//  GaussianTimeSeriesGenerator.swift
//  
//
//  Created by Blaine Rothrock on 10/18/22.
//

import Foundation
import GameKit

class GaussianTimeSeriesGenerator: TimeSeriesGenerator<Float> {
    private let random = GKRandomSource()
    private let gen: GKGaussianDistribution
    
    init(mean: Float, std: Float, step: Double, start: Date?=nil) {
        self.gen = GKGaussianDistribution(
            randomSource: random,
            mean: mean,
            deviation: std
        )
        
        super.init(step: step, start: start, kernel: { return Float($0) })
    }
    
    override func next(_ count: Int = 1) {
        for _ in 0...count {
            ts.add(epoch: cursor, values: [self.gen.nextUniform()])
            cursor += step
        }
    }
}
