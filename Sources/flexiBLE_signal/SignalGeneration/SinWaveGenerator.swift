//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 10/17/22.
//

import Foundation
import Accelerate

public class SinWaveGenerator: TimeSeriesGenerator {
    private var tau: Float = .pi * 2

    public var ts: TimeSeries<Float>
    public var cursor: Double
    public var step: Double
    public var i: Int
    var freq: Float

    let amplitude: Float
    let phase: Float
    
    public init(step: Double=1.0, start: Date?=nil, freq: Float, amplitude: Float = 1.0, phase: Float = 0.0) {
        self.ts = TimeSeries(persistence: 1000)
        self.cursor = start == nil ? 0.0 : start!.timeIntervalSince1970
        self.i = 0
        self.step = step
        self.freq = freq
        self.amplitude = amplitude
        self.phase = phase
    }
    
    public func next(_ count: Int = 1) {
        for _ in 0...count {
            let next = amplitude * sin( (Float(step) * Float(i) * freq * tau) + phase)
            ts.add(epoch: cursor, values: [next])
            cursor += step
            i += 1
        }
    }
}
