import Accelerate

let n = vDSP_Length(2048)

let frequencies: [Float] = [1,5,25,30,75,100,300,500,512,1023]

let tau: Float = .pi * 2
let signal: [Float] = (0...n).map { index in
    frequencies.reduce(0) { accumulator, frequencies in
        let normalizedIndex = Float(index) / Float(n)
        return accumulator + sin(normalizedIndex * frequencies * tau)
    }
}

func fft_forward<T>(signal: [Float], outputImag: inout [Float], outputReal: inout [Float], filter: vDSP.FFT<T>) where T: vDSP_FourierTransformable {
    
    
    let halfN = Int(signal.count/2)

    var inputReal = [Float](repeating: 0, count: halfN)
    var inputImag = [Float](repeating: 0, count: halfN)
    
    inputReal.withUnsafeMutableBufferPointer { inputRealPtr in
        inputImag.withUnsafeMutableBufferPointer { inputImagPtr in
            outputReal.withUnsafeMutableBufferPointer { outputRealPtr in
                outputImag.withUnsafeMutableBufferPointer { outputImagPtr in
                    
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
                    
                    filter.forward(input: input, output: &output)
                }
            }
        }
    }
}




func autoSpectrum(real: inout [Float], imag: inout [Float], n: Int) -> [Float] {
    let halfN = n / 2
    return [Float](unsafeUninitializedCapacity: halfN) { buffer, initializedCount in
        vDSP.clear(&buffer)
        
        real.withUnsafeMutableBufferPointer { realPtr in
            imag.withUnsafeMutableBufferPointer { imagPtr in
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


func fft_reverse<T>(real: inout [Float], imag: inout [Float], filter: vDSP.FFT<T>, n: Int) -> [Float] where T: vDSP_FourierTransformable {
    
    let halfN = n/2
    
    var inverseOutputReal = [Float](repeating: 0, count: halfN)
    var inverseOutputImag = [Float](repeating: 0, count: halfN)
    
    return real.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
        imag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
            inverseOutputReal.withUnsafeMutableBufferPointer { inverseOutputRealPtr in
                inverseOutputImag.withUnsafeMutableBufferPointer { inverseOutputImagPtr in
                    
                    let forwardOutput = DSPSplitComplex(
                        realp: forwardOutputRealPtr.baseAddress!,
                        imagp: forwardOutputImagPtr.baseAddress!
                    )
                    
                    var inverseOutput = DSPSplitComplex(
                        realp: inverseOutputRealPtr.baseAddress!,
                        imagp: inverseOutputImagPtr.baseAddress!
                    )
                    
                    
                    filter.inverse(
                        input: forwardOutput,
                        output: &inverseOutput
                    )
                    
                    let scale = 1 / Float(n*2)
                    return [Float](
                        fromSplitComplex: inverseOutput,
                        scale: scale,
                        count: Int(n)
                    )
                }
            }
        }
    }
}

let log2n = vDSP_Length(log2(Float(n)))

guard let fftSetUp = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self) else {
    fatalError("cannot create FFT")
}

var signalFFTForwardReal = [Float](repeating: 0, count: signal.count/2)
var signalFFTForwardImag = [Float](repeating: 0, count: signal.count/2)

fft_forward(signal: signal, outputImag: &signalFFTForwardImag, outputReal: &signalFFTForwardReal, filter: fftSetUp)
let autospectrum = autoSpectrum(real: &signalFFTForwardReal, imag: &signalFFTForwardImag, n: signal.count)

autospectrum.map { $0 }

let componentFrequencies = autospectrum.enumerated().filter {
    $0.element > 1
}.map { return $0.offset }


let recreatedSignal = fft_reverse(real: &signalFFTForwardReal, imag: &signalFFTForwardImag, filter: fftSetUp, n: signal.count)

recreatedSignal.map { $0 }
//
signal.map { $0 }


// low pass filter atempt
let fS: Float = 100
let fL: Float = 2
let bL: Float = 1
var M: Int = Int(4.0/(bL/fS))
if M % 2 == 0 { M += 1 }

var m = vDSP.ramp(in: 0.0...Float(M-1), count: M)
vDSP.subtract(m, [Float](repeating: (Float(M)-1.0)/2.0, count: M), result: &m)
vDSP.multiply(2*(fL/fS), m, result: &m)
m = m.map{ $0 == 0 ? 1 : sin(Float.pi*$0) / (Float.pi*$0) }
var blackman_window = [Float](repeating: 0, count: M)
vDSP_blkman_window(&blackman_window, vDSP_Length(M), 0)
blackman_window.map({ $0 })

vDSP.multiply(m, blackman_window, result: &m)
let mSum = vDSP.sum(m)
vDSP.divide(m, mSum, result: &m)

m.map { $0 }


m = m + [Float](repeating: 0, count: 2048 - m.count)
let ignalPadded = signal.count < 2048 ? signal + [Float](repeating: 0, count: 2048 - signal.count) : signal
//let filteredSignal = vDSP.convolve(signal, withKernel: m)
//filteredSignal.map({ $0 })

//filteredSignal.count


let filterLog2n = vDSP_Length(log2(Float(m.count)))

guard let filterFftSetUp = vDSP.FFT(log2n: filterLog2n, radix: .radix2, ofType: DSPSplitComplex.self) else {
    fatalError("cannot create FFT")
}

var filterFFTForwardReal = [Float](repeating: 0, count: m.count/2)
var filterFFTForwardImag = [Float](repeating: 0, count: m.count/2)

fft_forward(signal: m, outputImag: &filterFFTForwardImag, outputReal: &filterFFTForwardReal, filter: filterFftSetUp)
//let autospectrum = autoSpectrum(real: &signalFFTForwardReal, imag: &signalFFTForwardImag, n: signal.count)

var passReal = [Float](repeating: 0, count: m.count/2)
var passImag = [Float](repeating: 0, count: m.count/2)

signalFFTForwardReal.count
filterFFTForwardReal.count

vDSP.multiply(signalFFTForwardReal, filterFFTForwardReal, result: &passReal)
vDSP.multiply(signalFFTForwardImag, filterFFTForwardImag, result: &passImag)

signal
signal.map { $0 }
let filteredSignal = fft_reverse(real: &passReal, imag: &passImag, filter: filterFftSetUp, n: m.count)
filteredSignal.map { $0 }
