//
//  MinMaxScaling.swift
//  
//
//  Created by Blaine Rothrock on 3/17/23.
//

import Foundation
import Accelerate

public class MinMaxScalingFilter: SignalFilter {
    public var type: SignalFilterType = .minMaxScaling
    
    public var min: Double = Double.infinity
    public var max: Double = -Double.infinity
    
    public init() { }
    
    public func apply(to value: Float) -> Float {
        let dValue = Double(value)
        if dValue > max {
            max = dValue
        }
        
        if dValue < min {
            min = dValue
        }
        
        let delta = max - min
        return Float(delta / (dValue - delta))
    }
    
    public func apply(to value: Double) -> Double {
        if value > max {
            max = value
        }
        
        if value < min {
            min = value
        }
        
        let delta = max - min
        return delta / (value - delta)
    }
    
    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        (self.min, self.max) = Self.minMax(x: signal as! [Float], result: &result)
        return result as! U
    }
    
    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0.0, count: signal.count)
        (self.min, self.max) = Self.minMax(x: signal as! [Double], result: &result)
        return result as! U
    }
    
    static func minMax<U, V>(x: U, result: inout V) -> (min: Double, max: Double) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        let max = vDSP.maximum(x)
        let min = vDSP.minimum(x)
        let delta = max - min
        vDSP.add(-delta, x, result: &result)
        vDSP.divide(delta, result, result: &result)
        
        return (min: min, max: max)
    }

    static func minMax<U, V>(x: U, result: inout V) -> (min: Double , max: Double) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        let max = vDSP.maximum(x)
        let min = vDSP.minimum(x)
        let delta = max - min
        vDSP.add(-delta, x, result: &result)
        vDSP.divide(delta, result, result: &result)
        
        return (min: Double(min), max: Double(max))
    }
}
