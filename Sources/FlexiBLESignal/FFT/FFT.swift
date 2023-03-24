//
// Created by Blaine Rothrock on 11/17/22.
//

import Foundation
import Accelerate

public struct FFT {

    private var setup: vDSP.FFT<DSPSplitComplex>

    public let N: Int
    public var forwardReal: [Float] = []
    public var forwardImag: [Float] = []
    public var inverseReal: [Float] = []
    public var inverseImag: [Float] = []

    private var halfN: Int

    public init(N: Int) {
        self.N = N
        halfN = N/2
        let log2n = vDSP_Length(log2(Float(N)))

        guard let setup = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self) else {
            fatalError("unable to create FFT")
        }
        self.setup = setup
    }

    public mutating func clear() {
        forwardReal = []
        forwardImag = []
        inverseReal = []
        inverseImag = []
    }

    public mutating func forward(signal: [Float]) {
        let halfN = Int(signal.count/2)

        var inputReal = [Float](repeating: 0, count: halfN)
        var inputImag = [Float](repeating: 0, count: halfN)
        forwardReal = [Float](repeating: 0, count: halfN)
        forwardImag = [Float](repeating: 0, count: halfN)

        inputReal.withUnsafeMutableBufferPointer { inputRealPtr in
            inputImag.withUnsafeMutableBufferPointer { inputImagPtr in
                forwardReal.withUnsafeMutableBufferPointer { outputRealPtr in
                    forwardImag.withUnsafeMutableBufferPointer { outputImagPtr in

                        var input = DSPSplitComplex(
                                realp: inputRealPtr.baseAddress!,
                                imagp: inputImagPtr.baseAddress!
                        )

                        signal.withUnsafeBytes {
                            vDSP.convert(
                                    interleavedComplexVector: [DSPComplex]($0.bindMemory(to: DSPComplex.self)),
                                    toSplitComplexVector: &input
                            )
                        }

                        var output = DSPSplitComplex(
                                realp: outputRealPtr.baseAddress!,
                                imagp: outputImagPtr.baseAddress!
                        )

                        setup.forward(input: input, output: &output)
                    }
                }
            }
        }
    }

    public mutating func autoSpectrum() -> [Float] {
        return [Float](unsafeUninitializedCapacity: halfN) { buffer, initializedCount in
            vDSP.clear(&buffer)

            forwardReal.withUnsafeMutableBufferPointer { realPtr in
                forwardImag.withUnsafeMutableBufferPointer { imagPtr in
                    var freqDomain = DSPSplitComplex(
                            realp: realPtr.baseAddress!,
                            imagp: imagPtr.baseAddress!
                    )

                    vDSP_zaspec(
                            &freqDomain,
                            buffer.baseAddress!,
                            vDSP_Length(halfN)
                    )
                }
            }
            initializedCount = halfN
        }
    }

    public mutating func inverse() -> [Float] {
        inverseReal = [Float](repeating: 0, count: halfN)
        inverseImag = [Float](repeating: 0, count: halfN)

        return forwardReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
            forwardImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                inverseReal.withUnsafeMutableBufferPointer { inverseOutputRealPtr in
                    inverseImag.withUnsafeMutableBufferPointer { inverseOutputImagPtr in

                        let forwardOutput = DSPSplitComplex(
                                realp: forwardOutputRealPtr.baseAddress!,
                                imagp: forwardOutputImagPtr.baseAddress!
                        )

                        var inverseOutput = DSPSplitComplex(
                                realp: inverseOutputRealPtr.baseAddress!,
                                imagp: inverseOutputImagPtr.baseAddress!
                        )


                        setup.inverse(
                            input: forwardOutput,
                            output: &inverseOutput
                        )

                        let scale = 1 / Float(N*2)
                        return [Float](
                                fromSplitComplex: inverseOutput,
                                scale: scale,
                                count: Int(N)
                        )
                    }
                }
            }
        }
    }
    
    public static func applyFFT<U>(signal: U, kernel: [Float]) -> [Float] where U:Sequence, U:AccelerateBuffer, U.Element == Float {
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

    public static func spectralAnalysis(of signal: [Float]) -> [Float] {
        let length = nextPowerOf2(for: signal.count)
        let x = pad(x: signal, to: length)

        var fft = FFT(N: length)
        fft.forward(signal: x)
        return fft.autoSpectrum().map { sqrt($0) }
    }

    public static func componentFrequencies(of spectrum: [Float]) -> [Int] {
        return spectrum.enumerated()
            .filter{ $0.element > 1 }
            .map { return $0.offset }
    }
}
