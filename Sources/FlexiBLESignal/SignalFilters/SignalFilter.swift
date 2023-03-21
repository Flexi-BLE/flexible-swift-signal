//
//  SignalFilter.swift
//  
//
//  Created by Blaine Rothrock on 12/7/22.
//

import Foundation
import Accelerate

public enum SignalFilterType: String {
    case none = "None"
    case minMaxScaling = "Min Max Scaling"
    case zscore = "Z-Score Normalization"
    case demean = "Demean"
    case convolutionMovingAverage = "Moving Average"
    case lowPass = "Low Pass"
    case highPass = "High Pass"
    case bandPass = "Band Pass"
    case bandReject = "Band Reject"
    
    public var description: String {
        switch self {
        case .none: return "--"
        case .minMaxScaling: return "the process of rescaling the range of features to scale the range in [0, 1] or [−1, 1]"
        case .zscore: return "Z-score normalization refers to the process of normalizing every value in a dataset such that the mean of all of the values is 0 and the standard deviation is 1."
        case .demean: return "The mean is substracted from every point in the dataset"
        case .convolutionMovingAverage: return "A calculation to analyze data points by creating a series of averages of different subsets of the full data set"
        case .lowPass: return "A filter that passes signals with a frequency lower than a selected cutoff frequency and attenuates signals with frequencies higher than the cutoff frequency."
        case .highPass: return "A filter that passes signals with a frequency higher than a certain cutoff frequency and attenuates signals with frequencies lower than the cutoff frequency. "
        case .bandPass: return "A filter that passes frequencies within a certain range and rejects (attenuates) frequencies outside that range."
        case .bandReject: return "A filter that passes most frequencies unaltered, but attenuates those in a specific range to very low levels."
        }
    }
}

public protocol SignalFilter<FP> {
    associatedtype FP = FXBFloatingPoint
    var type: SignalFilterType { get }
    
    func apply(to value: Float) -> Float
    func apply(to value: Double) -> Double
    func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float
    func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double
}

public class EmptyFilter: SignalFilter {
    public var type: SignalFilterType = .none
    
    public init() { }
    
    public func apply(to value: Float) -> Float {
        return value
    }
    
    public func apply(to value: Double) -> Double {
        return value
    }
    
    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        return [Float]() as! U
    }
    
    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        return [Double]() as! U
    }
}
