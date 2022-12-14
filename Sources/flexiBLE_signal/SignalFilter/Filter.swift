//
// Created by Blaine Rothrock on 10/18/22.
//

import Foundation
import Accelerate

enum Filter {

    static func minMax<U, V>(x: U, result: inout V) -> (min: Double, max: Double) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        let max = vDSP.maximum(x)
        let min = vDSP.minimum(x)
        let delta = max - min
        vDSP.add(-delta, x, result: &result)
        vDSP.divide(delta, result, result: &result)
        
        return (min: min, max: max)
    }

    static func minMax<U, V>(x: U, result: inout V) -> (min: Float , max: Float) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        let max = vDSP.maximum(x)
        let min = vDSP.minimum(x)
        let delta = max - min
        vDSP.add(-delta, x, result: &result)
        vDSP.divide(delta, result, result: &result)
        
        return (min: min, max: max)
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

    static func zscore<U, V>(x: U, result: inout V) -> (mean: Double, std: Double) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        var mean: Double = 0.0
        var std: Double = 0.0
        vDSP_normalizeD(x as! [Double], 1, nil, 1, &mean, &std, vDSP_Length(x.count))

        vDSP.add(-mean, x, result: &result)
        vDSP.divide(result, std, result: &result)
        
        return (mean: mean, std: std)
    }

    static func zscore<U, V>(x: U, result: inout V) -> (mean: Float, std: Float) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        var mean: Float = 0.0
        var std: Float = 0.0
        vDSP_normalize(x as! [Float], 1, nil, 1, &mean, &std, vDSP_Length(x.count))

        vDSP.add(-mean, x, result: &result)
        vDSP.divide(result, std, result: &result)
        
        return (mean: mean, std: std)
    }

    static func movingAverage<U, V>(x: U, window N: Int, result: inout V) -> [Double] where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        let kernel = [Double](repeating: 1/Double(N), count: N)
        vDSP.convolve(x, withKernel: kernel, result: &result)
        
        return kernel
    }

    static func movingAverage<U, V>(x: U, window N: Int, result: inout V) -> [Float] where U: AccelerateBuffer, U: Sequence, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        let kernel = [Float](repeating: 1.0/Float(N), count: N)
        let padX = x + [Float](repeating: vDSP.mean(x), count: N)
        vDSP.convolve(padX, withKernel: kernel, result: &result)
        
        return kernel
    }

    static func lowPass<U,V>(
            x: U,
            frequency fS: Float,
            cutoff fL: Float,
            transition bL: Float,
            result: inout V
    ) -> [Float] where U: AccelerateBuffer, U:Sequence, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {

        let m = makeLowPassFilter(fS: fS, fL: fL, bL: bL)

        let r = Filter.applyFFT(signal: x, kernel: m)
        result = r as! V
        return m
    }

    static func highPass<U,V>(
            x: U,
            frequency fS: Float,
            cutoff fH: Float,
            transition bH: Float,
            result: inout V
    ) -> [Float] where U: AccelerateBuffer, U:Sequence, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {

        // create the filter
        let m = makeHighPassFilter(fS: fS, fH: fH, bH: bH)

        let r = Filter.applyFFT(signal: x, kernel: m)
        result =  r as! V
        return m
    }

    static func bandPass<U,V>(
            x: U,
            frequency fS: Float,
            cutoffHigh fH: Float,
            transitionHigh bH: Float,
            cutoffLow fL: Float,
            transitionLow bL: Float,
            result: inout V
    ) -> [Float] where U: AccelerateBuffer, U:Sequence, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {

        let m = makeBandPassFilter(fS: fS, fH: fH, bH: bH, fL: fL, bL: bL)

        let r = Filter.applyFFT(signal: x, kernel: m)
        result =  r as! V
        return m
    }

    static func bandReject<U,V>(
            x: U,
            frequency fS: Float,
            cutoffHigh fH: Float,
            transitionHigh bH: Float,
            cutoffLow fL: Float,
            transitionLow bL: Float,
            result: inout V
    ) -> [Float] where U: AccelerateBuffer, U:Sequence, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {

        let m = makeBandRejectFilter(fS: fS, fH: fH, bH: bH, fL: fL, bL: bL)
        let r = Filter.applyFFT(signal: x, kernel: m)
        result =  r as! V
        return m
    }
    
    static func applyFFT<U>(signal: U, kernel: [Float]) -> [Float] where U:Sequence, U:AccelerateBuffer, U.Element == Float {
        let length = nextPowerOf2(for: max(kernel.count, signal.count))
        let paddedSignal = pad(x: signal, to: length)
        let m = pad(x: kernel, to: length)

        // compute the impluse response of signal
        var fft = FFT(N: length)
        fft.forward(signal: paddedSignal)
        var signalIRReal = fft.forwardReal
        var signalIRImag = fft.forwardImag

        // compute impluse response for filter
        fft.clear()
        fft.forward(signal: m)
        var filterIRReal = fft.forwardReal
        var filterIRImag = fft.forwardImag

        vDSP.multiply(signalIRReal, filterIRReal, result: &filterIRReal)
        vDSP.multiply(signalIRImag, filterIRImag, result: &filterIRImag)

        fft.clear()
        fft.forwardReal = filterIRReal
        fft.forwardImag = filterIRImag
        let result = (Array(fft.inverse()[0..<signal.count]))
        fft.clear()
        
        return result
    }
    
//    static func applyFFT<U>(signal: U, kernel: U) -> (result: [Double], irKernel: [Double]) where U:Sequence, U:AccelerateBuffer, U.Element == Double {
//        let length = nextPowerOf2(for: max(kernel.count, signal.count))
//        let paddedSignal = pad(x: signal, to: length)
//        let m = pad(x: kernel, to: length)
//
//        // compute the impluse response of signal
//        var fft = FFT(N: length)
//        fft.forward(signal: paddedSignal)
//        var signalIRReal = fft.forwardReal
//        var signalIRImag = fft.forwardImag
//
//        // compute impluse response for filter
//        fft.clear()
//        fft.forward(signal: m)
//        var filterIRReal = fft.forwardReal
//        var filterIRImag = fft.forwardImag
//
//        vDSP.multiply(signalIRReal, filterIRReal, result: &filterIRReal)
//        vDSP.multiply(signalIRImag, filterIRImag, result: &filterIRImag)
//
//        fft.clear()
//        fft.forwardReal = filterIRReal
//        fft.forwardImag = filterIRImag
//        let result = (Array(fft.inverse()[0..<signal.count]))
//        fft.clear()
//
//        return (result: result, irKernel: filterIRReal)
//    }
}
