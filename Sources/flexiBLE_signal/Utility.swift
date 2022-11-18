//
//  Utility.swift
//  
//
//  Created by blaine on 10/18/22.
//

import Foundation
import Accelerate

func nextPowerOf2(for x: Int) -> Int {
    var out: Int = 1
    while (out <= x) {
        out = out << 1
    }
    return out
}

func pad<T>(x: T, to len: Int) -> [Float] where T: AccelerateBuffer, T:Sequence, T.Element == Float  {
    guard len >= x.count else { return x as! [Float] }
    return x + [Float](repeating: 0.0, count: len - x.count)
}

func makeLowPassFilter(fS: Float, fL: Float, bL: Float) -> [Float] {
    var M: Int = Int((4.0/(bL/fS)).rounded())
    if M % 2 == 0 { M += 1 } // M must be odd

    var m = vDSP.ramp(in: 0.0...Float(M-1), count: M)
    vDSP.subtract(m, [Float](repeating: (Float(M)-1.0)/2.0, count: M), result: &m)
    vDSP.multiply(2*(fL/fS), m, result: &m)

    // apply sinc
    m = m.map{ $0 == 0 ? 1 : sin(Float.pi*$0) / (Float.pi*$0) }

    // constrcut blackman window
    var blackman_window = [Float](repeating: 0, count: M)
    vDSP_blkman_window(&blackman_window, vDSP_Length(M), 0)

    // apply blackman to filter
    vDSP.multiply(m, blackman_window, result: &m)

    // normalize the filter
    let mSum = vDSP.sum(m)
    vDSP.divide(m, mSum, result: &m)

    return m
}

func makeHighPassFilter(fS: Float, fH: Float, bH: Float) -> [Float] {
    var m = makeLowPassFilter(fS: fS, fL: fH, bL: bH)
    // spectral inversion
    vDSP.multiply([Float](repeating: -1.0, count: m.count), m, result: &m)
    m[Int(m.count/2)] += 1.0

    return m
}

func makeBandPassFilter(fS: Float, fH: Float, bH: Float, fL: Float, bL: Float) -> [Float] {
    let lp = makeLowPassFilter(fS: fS, fL: fL, bL: bL)
    var m = makeHighPassFilter(fS: fS, fH: fH, bH: bH)
    vDSP.convolve(lp, withKernel: m, result: &m)
    return m
}

func makeBandRejectFilter(fS: Float, fH: Float, bH: Float, fL: Float, bL: Float) -> [Float] {
    let lp = makeLowPassFilter(fS: fS, fL: fL, bL: bL)
    var m = makeHighPassFilter(fS: fS, fH: fH, bH: bH)
    vDSP.add(lp, m, result: &m)
    return m
}
