//
// Created by Blaine Rothrock on 11/17/22.
//

import Foundation
import Accelerate

class CombinationSinWaveGenerator: TimeSeriesGenerator {
    private var tau: Float = .pi * 2
    var frequencies: [Float]
    var step: Double
    var cursor: Double
    var i: Int = 0
    var ts: TimeSeries<Float>

    init(frequencies: [Float], step: Double=1.0, start: Date?=nil) {
        self.frequencies = frequencies
        self.ts = TimeSeries(persistence: 1000)
        self.cursor = start == nil ? 0.0 : start!.timeIntervalSince1970
        self.step = step
    }

    func next(_ count: Int = 1) {
        for _ in 0...count {
            let next = frequencies.reduce(0) { accumulator, freq in
                return accumulator + sin( (((Float(step)/60.0) * Float(i)) * freq * tau))
            }
            ts.add(epoch: cursor, values: [next])
            cursor += step
            i += 1
        }
    }
}