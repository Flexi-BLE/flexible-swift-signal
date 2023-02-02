//
// Created by Blaine Rothrock on 11/17/22.
//

import XCTest
import Accelerate
@testable import FlexiBLESignal

final class FFTTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func signal(frequencies: [Int] = [1,5,25,30,75,100,300,500,512,1023], length: Int = 2048) -> [Float] {
        let n = vDSP_Length(length)

        let tau: Float = .pi * 2
        return (0...n).map { index in
            frequencies.reduce(0) { accumulator, frequencies in
                let normalizedIndex = Float(index) / Float(n)
                return accumulator + sin(normalizedIndex * Float(frequencies) * tau)
            }
        }
    }

    func testInitialization() throws {

        var length: Int = 2048
        var fft = FFT(N: length)

        var frequencies: [Int] = [1,5,25,30,75,100,300,500,512,1023]
        var s = signal(frequencies: frequencies, length: length)
        fft.forward(signal: s)
        var spectrum = fft.autoSpectrum()

        var componentFrequencies = spectrum.enumerated()
            .filter{ $0.element > 1 }
            .map { return $0.offset }

        XCTAssertEqual(frequencies, componentFrequencies)

        frequencies = [5]
        s = signal(frequencies: frequencies, length: length)
        fft.forward(signal: s)
        spectrum = fft.autoSpectrum()
        componentFrequencies = spectrum.enumerated()
            .filter{ $0.element > 1 }
            .map { return $0.offset }

        XCTAssertEqual(frequencies, componentFrequencies)

        frequencies = [100, 200, 300, 400]
        s = signal(frequencies: frequencies, length: length)
        fft.forward(signal: s)
        spectrum = fft.autoSpectrum()
        componentFrequencies = spectrum.enumerated()
            .filter{ $0.element > 1 }
            .map { return $0.offset }

        XCTAssertEqual(frequencies, componentFrequencies)
    }

    func testForwardPerformance() {
        let frequencies: [Int] = [1,5,25,30,75,100,300,500,512,1023]
        let signal = signal(frequencies: frequencies, length: 16384)
        var fft = FFT(N: signal.count)


        self.measure {
            fft.forward(signal: signal)
            fft.clear()
        }
    }

    func testAutoSpecPerformance() {
        let frequencies: [Int] = [1,5,25,30,75,100,300,500,512,1023]
        let signal = signal(frequencies: frequencies, length: 16384)
        var fft = FFT(N: signal.count)

        self.measure {
            fft.forward(signal: signal)
            let spectrum = fft.autoSpectrum()
            fft.clear()
        }
    }

    func testInversePerformance() {
        let frequencies: [Int] = [1,5,25,30,75,100,300,500,512,1023]
        let signal = signal(frequencies: frequencies, length: 16384)
        var fft = FFT(N: signal.count)
        fft.forward(signal: signal)

        self.measure {
            let newSignal = fft.inverse()
        }
    }
}
