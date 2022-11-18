//
// Created by Blaine Rothrock on 11/17/22.
//

import Foundation

protocol TimeSeriesGenerator {
    associatedtype T: FXBFloatingPoint

    var ts: TimeSeries<T> { get }
    var cursor: Double { get }
    var i: Int { get }
    var step: Double { get }

    func next(_ count: Int)
}