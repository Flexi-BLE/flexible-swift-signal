//
//  ExponentiallyWeightedMovingAverage.swift
//  
//
//  Created by Blaine Rothrock on 3/17/23.
//

import Foundation
import Accelerate


public class ExponentiallyWeightedMovingAverage: SignalFilter {
    public var type: SignalFilterType = .minMaxScaling
    
    public var alpha: Double
    public private(set) var movingAverage: Double = 0.0
    
    public init(alpha: Double) {
        self.alpha = alpha
    }
    
    public func apply(to value: Float) -> Float {
        movingAverage = recursiveMovingAverageCalc(value: Double(value))
        return Float(movingAverage)
    }
    
    public func apply(to value: Double) -> Double {
        movingAverage = recursiveMovingAverageCalc(value: value)
        return movingAverage
    }
    
    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        let fsignal = signal as! [Float]
        
        for (i, value) in fsignal.enumerated() {
            result[i] = self.apply(to: value)
        }
        
        return result as! U
    }
    
    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0.0, count: signal.count)
        let fsignal = signal as! [Double]
        
        for (i, value) in fsignal.enumerated() {
            result[i] = self.apply(to: value)
        }
        
        return result as! U
    }
    
    public func recursiveMovingAverageCalc(value: Double) -> Double {
        return (alpha * value) + ((1.0-alpha) * movingAverage)
    }
}
