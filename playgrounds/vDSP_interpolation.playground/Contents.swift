//: A UIKit based Playground for presenting user interface
  
import Accelerate
import simd
import UIKit
import PlaygroundSupport

typealias point = (x: Double, y: Double)
typealias tsPoint = (x: Date, y: Double)

// read real data from csv
let dateFormatter = DateFormatter()
dateFormatter.timeZone = .gmt
dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS"

var data: [tsPoint] = []

do {
    let fileURL = Bundle.main.url(forResource: "data1", withExtension: "csv")
    let content = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
    data = content.split(separator: "\n").compactMap { row in
        let splits = row.split(separator: ",")
        if splits.count == 2 {
            if let date = dateFormatter.date(from: String(splits[0])),
               let val: Double = Double(splits[1]) {
                return tsPoint(x: date, y: val)
            }
        }
        return nil
    }
    data = Array(data.reversed())
} catch {
    print(error)
}


// identify actual freqnency
let rawX = data.map({ $0.x.timeIntervalSince1970 })
let rawXEnd = rawX.last!
let rawXStart = rawX.first!
let rawXRange = rawXEnd - rawXStart
let rawY = data.map({ Float($0.y) })

let dateOffsets: [Float] = zip(rawX, rawX.dropFirst()).map { Float(round(1000 * ($1-$0)) / 1000) }
print(rawX)
print(dateOffsets)

let avg = vDSP.mean(dateOffsets)
let max = vDSP.maximum(dateOffsets)
let maxIdx = vDSP.indexOfMaximum(dateOffsets)
let min = vDSP.minimum(dateOffsets)
let sum = vDSP.sum(dateOffsets)

let controlVec: [Float] = vDSP.ramp(
    withInitialValue: 0.0,
    increment: 0.02,
    count: 1024
)

let result = vDSP.linearInterpolate(
    elementsOf: rawY,
    using: controlVec
)

let mix = simd_mix(-100, 100, 0.25)


//let controlVector: [Float] = vDSP.ramp(
//    in: 0 ... Float(rawXRange) - 1,
//    count: 1024
//)
//let result = vDSP.linearInterpolate(
//    elementsOf: values
//    using: controlVector
//)
