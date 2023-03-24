//
// Created by Blaine Rothrock on 10/18/22.
//

import Foundation
import Accelerate
import simd

extension vDSP {
//    static func std<U>(_ vector: U) -> Double where U: AccelerateBuffer, U.Element == Double {
//        let mean = vDSP.mean(vector)
//        let n = vector.count
//
//
//        var result = [Double](repeating: 0.0, count: n)
//        vDSP.add(-mean, vector, result: &result)
//        vDSP.square(result, result: &result)
//        let sum = vDSP.sum(result)
//        return (1.0/Double(n-1)) * sum
//    }
//
//    static func std<U>(_ vector: U) -> Float where U: AccelerateBuffer, U.Element == Float {
//        let mean = vDSP.mean(vector)
//        let n = vector.count
//
//        var result = [Float](repeating: 0.0, count: n)
//        vDSP.add(-mean, vector, result: &result)
//        vDSP.square(result, result: &result)
//        let sum = vDSP.sum(result)
//        return (1.0/Float(n-1)) * sum
//    }

    static func sinc<U, V>(_ vector: U, result: inout V) where U: AccelerateBuffer, V: AccelerateMutableBuffer,  U.Element == Double, V.Element == Double {
        // shift entire vector to ensure no zeros
        var x = [Double](repeating: Double.leastNormalMagnitude, count: vector.count)
        vDSP.add(vector, x, result: &x)

        var denominator = [Double](repeating: 0.0, count: vector.count)
        vDSP.multiply(Double.pi, x, result: &denominator)
        let numerator = denominator.map({sin($0)})

        vDSP.divide(numerator, denominator, result: &result)
    }
}