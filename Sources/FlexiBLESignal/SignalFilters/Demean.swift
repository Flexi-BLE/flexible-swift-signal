//
//  Demean.swift
//  
//
//  Created by Blaine Rothrock on 3/17/23.
//

import Foundation
import Accelerate

public class DemeanFilter: SignalFilter {
    public var type: SignalFilterType = .demean
    
    public var mean: Double = 0.0
    
    private var sumX: Double = 0.0
    private var n: Int = 0
    
    public init() {  }
    
    public func apply(to value: Float) -> Float {
        let dValue = Double(value)
        sumX += dValue
        n += 1
        mean = sumX / Double(n)
        
        return value - Float(mean)
    }
    
    public func apply(to value: Double) -> Double {
        sumX += value
        n += 1
        mean = sumX / Double(n)
        
        return value - mean
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        
        sumX = Double(vDSP.sum(signal))
        n = signal.count
        
        mean = Double(Self.demean(x: signal as! [Float], result: &result))
        return result as! U
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0.0, count: signal.count)
        
        sumX = vDSP.sum(signal)
        n = signal.count
        mean = Self.demean(x: signal as! [Double], result: &result)
        
        return result as! U
    }
    
    static func demean<U, V>(x: U, result: inout V) -> Double where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        let mean = vDSP.mean(x)
        vDSP.add(-mean, x, result: &result)
        return mean
    }

    static func demean<U, V>(x: U, result: inout V) -> Float where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        let mean = vDSP.mean(x)
        vDSP.add(-mean, x, result: &result)
        return mean
    }
}
