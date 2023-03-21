//
//  ZScore.swift
//  
//
//  Created by Blaine Rothrock on 3/17/23.
//

import Foundation
import Accelerate

public class ZScoreFilter: SignalFilter {
    public var type: SignalFilterType = .zscore

    public var mean: Double = 0.0
    public var std: Double = 1.0
    
    private var sumX2: Double = 0.0
    private var sumX: Double = 0.0
    private var n: Int = 0
    
    public init() {  }
    
    public func apply(to value: Float) -> Float {
        var dValue = Double(value)
        sumX += dValue
        sumX2 += dValue*dValue
        n += 1
        
        mean = sumX / Double(n)
        std = sqrt(sumX2/Double(n)) - (mean*mean)
        
        return Float((dValue - mean) / std)
    }
    
    public func apply(to value: Double) -> Double {
        sumX += value
        sumX2 += value*value
        n += 1
        
        mean = sumX / Double(n)
        std = sqrt(sumX2/Double(n)) - (mean*mean)
        
        return (value - mean) / std
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        
        sumX = Double(vDSP.sum(signal))
        sumX2 = Double(vDSP.sum(vDSP.square(signal)))
        n = signal.count
        
        (self.mean, self.std) = Self.zscore(x: signal as! [Float], result: &result)
        return result as! U
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0.0, count: signal.count)
        
        sumX = vDSP.sum(signal)
        sumX2 = vDSP.sum(vDSP.square(signal))
        n = signal.count
        
        (self.mean, self.std) = Self.zscore(x: signal as! [Double], result: &result)
        return result as! U
    }
    
    static func zscore<U, V>(x: U, result: inout V) -> (mean: Double, std: Double) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        var mean: Double = 0.0
        var std: Double = 0.0
        vDSP_normalizeD(x as! [Double], 1, nil, 1, &mean, &std, vDSP_Length(x.count))

        vDSP.add(-mean, x, result: &result)
        vDSP.divide(result, std, result: &result)
        
        return (mean: mean, std: std)
    }

    static func zscore<U, V>(x: U, result: inout V) -> (mean: Double, std: Double) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        var mean: Float = 0.0
        var std: Float = 0.0
        vDSP_normalize(x as! [Float], 1, nil, 1, &mean, &std, vDSP_Length(x.count))

        vDSP.add(-mean, x, result: &result)
        vDSP.divide(result, std, result: &result)
        
        return (mean: Double(mean), std: Double(std))
    }
}
