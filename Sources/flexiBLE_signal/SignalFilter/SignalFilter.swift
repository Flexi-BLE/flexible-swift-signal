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
    case movingAverage = "Moving Average"
    case lowPass = "Low Pass"
    case highPass = "High Pass"
    case bandPass = "Band Pass"
    case bandReject = "Band Reject"
    
    var description: String {
        switch self {
        case .none: return "--"
        case .minMaxScaling: return "the process of rescaling the range of features to scale the range in [0, 1] or [−1, 1]"
        case .zscore: return "Z-score normalization refers to the process of normalizing every value in a dataset such that the mean of all of the values is 0 and the standard deviation is 1."
        case .demean: return "The mean is substracted from every point in the dataset"
        case .movingAverage: return "A calculation to analyze data points by creating a series of averages of different subsets of the full data set"
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
    
    func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float
    func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double
}

public class MinMaxScalingFilter: SignalFilter {
    public var type: SignalFilterType = .minMaxScaling
    
    public var min: FP?
    public var max: FP?
    
    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        (self.min, self.max) = Filter.minMax(x: signal as! [Float], result: &result)
        return result as! U
    }
    
    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0.0, count: signal.count)
        (self.min, self.max) = Filter.minMax(x: signal as! [Double], result: &result)
        return result as! U
    }
}

public class ZScoreFilter: SignalFilter {
    public var type: SignalFilterType = .zscore

    public var mean: FP?
    public var std: FP?

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        (self.mean, self.std) = Filter.zscore(x: signal as! [Float], result: &result)
        return result as! U
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0.0, count: signal.count)
        (self.mean, self.std) = Filter.zscore(x: signal as! [Double], result: &result)
        return result as! U
    }
}


public class DemeanFilter: SignalFilter {
    public var type: SignalFilterType = .demean

    public var mean: FP?

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        self.mean = Filter.demean(x: signal as! [Float], result: &result)
        return result as! U
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        var result = [Double](repeating: 0.0, count: signal.count)
        self.mean = Filter.demean(x: signal as! [Double], result: &result)
        return result as! U
    }
}

public class MovingAverageFilter: SignalFilter {
    public var type: SignalFilterType = .movingAverage
    public var window: Int

    public var kernel: [FP]?

    init(window: Int) {
        self.window = window
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        kernel = Filter.movingAverage(x: signal as! [Float], window: self.window, result: &result)
        return result as! U
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        fatalError("No double support for moving average filter")
    }
}


public class LowPassFilter: SignalFilter {
    public var type: SignalFilterType = .lowPass

    public var frequency: Float
    public var cutoffFrequency: Float
    public var transitionFrequency: Float

    var kernel: [FP]?

    init(frequency: Float, cutoffFrequency: Float, transitionFrequency: Float) {
        self.frequency = frequency
        self.cutoffFrequency = cutoffFrequency
        self.transitionFrequency = transitionFrequency
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        kernel = Filter.lowPass(
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
}

public class HighPassFilter: SignalFilter {
    public var type: SignalFilterType = .highPass

    public var frequency: Float
    public var cutoffFrequency: Float
    public var transitionFrequency: Float

    public var kernel: [FP]?

    init(frequency: Float, cutoffFrequency: Float, transitionFrequency: Float) {
        self.frequency = frequency
        self.cutoffFrequency = cutoffFrequency
        self.transitionFrequency = transitionFrequency
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        kernel = Filter.highPass(
            x: signal as! [Float],
            frequency: frequency,
            cutoff: cutoffFrequency,
            transition: transitionFrequency,
            result: &result
        )
        return result as! U
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Double {
        fatalError("No double support for high pass filter")
    }
}

public class BandPassFilter: SignalFilter {
    public var type: SignalFilterType = .bandPass

    public var frequency: Float
    public var cutoffFrequencyHigh: Float
    public var transitionFrequencyHigh: Float
    public var cutoffFrequencyLow: Float
    public var transitionFrequencyLow: Float

    public var kernel: [FP]?

    init(
        frequency: Float,
        cutoffFrequencyHigh: Float,
        transitionFrequencyHigh: Float,
        cutoffFrequencyLow: Float,
        transitionFrequencyLow: Float
    ) {
        self.frequency = frequency
        self.cutoffFrequencyHigh = cutoffFrequencyHigh
        self.transitionFrequencyHigh = transitionFrequencyHigh
        self.cutoffFrequencyLow = cutoffFrequencyHigh
        self.transitionFrequencyLow = transitionFrequencyHigh
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        kernel = Filter.bandPass(
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
}

public class BandRejectFilter: SignalFilter {
    public var type: SignalFilterType = .bandReject

    public var frequency: Float
    public var cutoffFrequencyHigh: Float
    public var transitionFrequencyHigh: Float
    public var cutoffFrequencyLow: Float
    public var transitionFrequencyLow: Float

    public var kernel: [FP]?

    init(
        frequency: Float,

        cutoffFrequencyHigh: Float,
        transitionFrequencyHigh: Float,
        cutoffFrequencyLow: Float,
        transitionFrequencyLow: Float
    ) {
        self.frequency = frequency
        self.cutoffFrequencyHigh = cutoffFrequencyHigh
        self.transitionFrequencyHigh = transitionFrequencyHigh
        self.cutoffFrequencyLow = cutoffFrequencyHigh
        self.transitionFrequencyLow = transitionFrequencyHigh
    }

    public func apply<U>(to signal: U) -> U where U: AccelerateBuffer, U.Element == Float {
        var result = [Float](repeating: 0.0, count: signal.count)
        kernel = Filter.bandReject(
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
}
