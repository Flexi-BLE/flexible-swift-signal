import SwiftUI
import Charts
import Accelerate
import PlaygroundSupport

typealias point = (x: Double, y: Double)
typealias tsPoint = (x: Date, y: Double)

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

// create a date range
let start = Date.now.addingTimeInterval(-(10 * 1023) / 1000)
let end = Date.now
let X = stride(from: start, through: end, by: 0.01).map { Double($0.timeIntervalSince1970) }

// create a sample signal of the same size
let Y = (0 ..< X.count).map {
    sin(Double($0) * 0.007) + sin(Double($0) * 0.03)
}




// Antialiasing Filter (decimate by 4)
let decimationFactor = 32
let filterLength: vDSP_Length = vDSP_Length(decimationFactor)
let filter = [Double](repeating: 1 / Double(filterLength),
                     count: Int(filterLength))

let Xs = vDSP.downsample(X, decimationFactor: decimationFactor, filter: filter)
let Ys = vDSP.downsample(Y, decimationFactor: decimationFactor, filter: filter)
//
let resampledPoints = zip(Xs, Ys).map { tsPoint(x: Date(timeIntervalSince1970: $0), y: $1) }
let points = zip(X, Y).map { tsPoint(x: Date(timeIntervalSince1970: $0), y: $1) }


struct ContentView: View {
    var data: [(cat: String, points: [tsPoint])]
    
    var body: some View {
        VStack {
            Chart {
                ForEach(data, id: \.cat) { cat, points in
                    ForEach(points, id: \.x) { p in
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
            (cat: "raw", points: points),
            (cat: "resampled", points: resampledPoints)
        ]
    )
)
