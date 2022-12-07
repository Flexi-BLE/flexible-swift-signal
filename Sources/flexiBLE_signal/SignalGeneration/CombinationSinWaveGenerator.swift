//
// Created by Blaine Rothrock on 11/17/22.
//

import Foundation
import Accelerate

public class CombinationSinWaveGenerator: TimeSeriesGenerator {
    private var tau: Float = .pi * 2
    public var frequencies: [Float]
    public var step: Double
    public var cursor: Double
    public var i: Int = 0
    public var ts: TimeSeries<Float>

    public init(frequencies: [Float], step: Double=1.0, start: Date?=nil, persistence: Int = 1000) {
        self.frequencies = frequencies
        self.ts = TimeSeries(persistence: persistence)
        self.cursor = start == nil ? 0.0 : start!.timeIntervalSince1970
        self.step = step
    }

    public func next(_ count: Int = 1) {
        for _ in 0...count { 
            let next = frequencies.reduce(0) { accumulator, freq in
                return accumulator + sin( (Float(step) * Float(i) * freq) )
            }
            ts.add(epoch: cursor, values: [next])
            cursor += step
            i += 1
        }
    }
}
