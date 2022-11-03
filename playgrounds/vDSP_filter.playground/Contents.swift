import Accelerate
import SwiftUI
import Charts
import PlaygroundSupport

typealias Point = (x: Double, y: Double)
typealias tsPoint = (x: Date, y: Double)

// read real data from csv
let dateFormatter = DateFormatter()
dateFormatter.timeZone = .gmt
dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS"

var data: [Double] = []

do {
    let fileURL = Bundle.main.url(forResource: "ecg", withExtension: "csv")
    let content = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
    data = content.split(separator: "\n").compactMap { row in
        let splits = row.split(separator: ",")
        if splits.count >= 1 {
            if let val: Double = Double(splits[0]) {
                return val
            }
        }
        return nil
    }
    data = Array(data.reversed())
} catch {
    print(error)
}

let X = vDSP.ramp(
    withInitialValue: 0.0,
    increment: 1.0,
    count: data.count
)

let Y = data
let N = 20
let H = [Double](
    repeating: 1.0 / Double(N),
    count: N
)

let conv = vDSP.convolve(Y, withKernel: H)

let rawPoints = zip(X, Y).map({ Point(x: $0, y: $1) })
let movingAvgPoints = zip(X, conv).map({ Point(x: $0, y: $1) })

struct ContentView: View {
    var data: [(cat: String, points: [Point])]
    
    var body: some View {
        VStack {
            Chart {
                ForEach(data, id: \.cat) { cat, points in
                    ForEach(points, id: \.0) { p in
                        LineMark(
                            x: .value("ts", p.x),
                            y: .value("val", p.y)
                        ).foregroundStyle(by: .value("raw", cat))
                    }
                }
            }
            .frame(width: 500, height: 300)
        }
    }
}

PlaygroundPage.current.setLiveView(
    ContentView(
        data: [
            (cat: "raw", points: rawPoints),
            (cat: "movingAverage", points: movingAvgPoints)
        ]
    )
)
