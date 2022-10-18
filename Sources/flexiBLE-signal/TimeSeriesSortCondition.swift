//
// Created by Blaine Rothrock on 10/20/22.
//

import Foundation

public struct TimeSeriesSortCondition<T: FXBFloatingPoint> {
    public let colIdx: Int
    public let filter: (T)->Bool
    public let include: [Int]

    public init(colIdx: Int, filter: @escaping (T)->Bool, include: [Int], names: [String?]? = nil) {
        self.colIdx = colIdx
        self.filter = filter
        self.include = include
    }

    public static func all(_ idx: Int, name: String? = nil, include: [Int]) -> TimeSeriesSortCondition<T> {
        TimeSeriesSortCondition<T>(
                colIdx: idx,
                filter: { _ in true },
                include: [idx]
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
