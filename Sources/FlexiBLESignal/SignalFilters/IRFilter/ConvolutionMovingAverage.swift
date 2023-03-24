//
//  ConvolutionMovingAverage.swift
//  
//
//  Created by Blaine Rothrock on 3/17/23.
//

import Foundation
import Accelerate

public class ConvolutionMovingAverage: IRFilter {
    public var type: SignalFilterType = .convolutionMovingAverage
    public var window: Int

    public var kernel: [FP]?

    public init(window: Int) {
        self.window = window
    }
    
    public func apply(to value: Float) -> Float {
        // TODO: implement running conv moving average
        return value
    }
    
    public func apply(to value: Double) -> Double {
        // TODO: implement running conv moving average
        return value
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        kernel = Self.convolutionMovingAverage(x: signal as! [Float], window: self.window, result: &result)
        return result as! U
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        fatalError("No double support for moving average filter")
    }
    
    static func convolutionMovingAverage<U, V>(x: U, window N: Int, result: inout V) -> [Double] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        let kernel = [Double](repeating: 1/Double(N), count: N)
        vDSP.convolve(x, withKernel: kernel, result: &result)
        
        return kernel
    }

    static func convolutionMovingAverage<U, V>(x: U, window N: Int, result: inout V) -> [Float] where U: AccelerateBuffer, U: Sequence, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        let kernel = [Float](repeating: 1.0/Float(N), count: N)
        let padX = x + [Float](repeating: vDSP.mean(x), count: N)
        vDSP.convolve(padX, withKernel: kernel, result: &result)
        
        return kernel
    }
}
