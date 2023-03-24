//
//  LowPass.swift
//  
//
//  Created by Blaine Rothrock on 3/17/23.
//

import Foundation
import Accelerate

public class LowPassFilter: IRFilter {
    public var type: SignalFilterType = .lowPass

    public var frequency: Float
    public var cutoffFrequency: Float
    public var transitionFrequency: Float

    public var kernel: [FP]?

    public init(frequency: Float, cutoffFrequency: Float, transitionFrequency: Float) {
        self.frequency = frequency
        self.cutoffFrequency = cutoffFrequency
        self.transitionFrequency = transitionFrequency
    }
    
    public func apply(to value: Float) -> Float {
        // TODO: implement running lowpass
        return value
    }
    
    public func apply(to value: Double) -> Double {
        // TODO: implement running lowpass
        return value
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        kernel = Self.lowPass(
            x: signal as! [Float],
            frequency: frequency,
            cutoff: cutoffFrequency,
            transition: transitionFrequency,
            result: &result
        )
        return result as! U
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        fatalError("No double support for low pass filter")
    }
    
    static func lowPass<U,V>(
            x: U,
            frequency fS: Float,
            cutoff fL: Float,
            transition bL: Float,
            result: inout V
    ) -> [Float] where U: AccelerateBuffer, U:Sequence, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {

        let m = makeLowPassFilter(fS: fS, fL: fL, bL: bL)

        let r = FFT.applyFFT(signal: x, kernel: m)
        result = r as! V
        return m
    }
}
