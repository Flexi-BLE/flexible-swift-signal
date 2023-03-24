//
//  Bandpass.swift
//  
//
//  Created by Blaine Rothrock on 3/17/23.
//

import Foundation
import Accelerate

public class BandPassFilter: IRFilter {
    public var type: SignalFilterType = .bandPass

    public var frequency: Float
    public var cutoffFrequencyHigh: Float
    public var transitionFrequencyHigh: Float
    public var cutoffFrequencyLow: Float
    public var transitionFrequencyLow: Float

    public var kernel: [FP]?

    public init(
        frequency: Float,
        cutoffFrequencyHigh: Float,
        transitionFrequencyHigh: Float,
        cutoffFrequencyLow: Float,
        transitionFrequencyLow: Float
    ) {
        self.frequency = frequency
        self.cutoffFrequencyHigh = cutoffFrequencyHigh
        self.transitionFrequencyHigh = transitionFrequencyHigh
        self.cutoffFrequencyLow = cutoffFrequencyLow
        self.transitionFrequencyLow = transitionFrequencyLow
    }
    
    public func apply(to value: Float) -> Float {
        // TODO: implement running bandpass
        return value
    }
    
    public func apply(to value: Double) -> Double {
        // TODO: implement running bandpass
        return value
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        kernel = Self.bandPass(
            x: signal as! [Float],
            frequency: frequency,
            cutoffHigh: cutoffFrequencyHigh,
            transitionHigh: transitionFrequencyHigh,
            cutoffLow: cutoffFrequencyLow,
            transitionLow: transitionFrequencyLow,
            result: &result
        )
        return result as! U
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        fatalError("No double support for band pass filter")
    }
    
    static func bandPass<U,V>(
            x: U,
            frequency fS: Float,
            cutoffHigh fH: Float,
            transitionHigh bH: Float,
            cutoffLow fL: Float,
            transitionLow bL: Float,
            result: inout V
    ) -> [Float] where U: AccelerateBuffer, U:Sequence, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {

        let m = makeBandPassFilter(fS: fS, fH: fH, bH: bH, fL: fL, bL: bL)

        let r = FFT.applyFFT(signal: x, kernel: m)
        result =  r as! V
        return m
    }
}
