//
// Created by Blaine Rothrock on 10/20/22.
//

import Foundation

public struct TimeSeriesSortCondition<T: FXBFloatingPoint> {
    // the column id to sort on
    public let colIdx: Int
    // the filter fn
    public let filter: (T)->Bool
    // the columns to include in the new time series objects (post sort)
    public let include: [Int]
    // the names of each column (from include) -- if null will use names from the source time series
    public let names: [String]?

    public init(colIdx: Int, filter: @escaping (T)->Bool, include: [Int], names: [String]? = nil) {
        self.colIdx = colIdx
        self.filter = filter
        self.include = include
        self.names = names
    }

    public static func all(_ idx: Int, name: String? = nil, include: [Int]) -> TimeSeriesSortCondition<T> {
        TimeSeriesSortCondition<T>(
                colIdx: idx,
                filter: { _ in true },
                include: [idx],
                names: name == nil ? nil : [name!]
        )
    }

    public static func none(_ idx: Int) -> TimeSeriesSortCondition {
        TimeSeriesSortCondition(
                colIdx: idx,
                filter: { _ in false },
                include: [idx]
        )
    }
}  // =  (colIdx: Int, filter: (T)->Bool, include: [Int], names: [String?])
