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
}