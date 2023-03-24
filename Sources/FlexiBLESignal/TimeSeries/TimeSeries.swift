//
//  TimeSeries.swift
//  
//
//  Created by Blaine Rothrock on 10/17/22.
//

import Foundation
import Accelerate

public protocol FXBFloatingPoint: FloatingPoint, Equatable { }
extension Float: FXBFloatingPoint { }
extension Double: FXBFloatingPoint { }

typealias TimeSeriesIndex = Double

public class TimeSeries<T: FXBFloatingPoint>: Equatable {
    
    public static func == (lhs: TimeSeries<T>, rhs: TimeSeries<T>) -> Bool {
        return lhs.colCount == rhs.colCount && lhs.count == rhs.count && lhs.columns == rhs.columns
    }
    
    public private(set) var index: Array<Double>

    public private(set) var columns: [TimeSeriesColumn<T>]
    
    public private(set) var persistence: Int

    public enum Operation {
        case add
        case subtract
        case multiply
        case divide
    }
    
    public init(persistence: Int) {
        self.index = []
        self.columns = []
        self.persistence = persistence
    }
    
    public init(with dates: [Date], columns: [TimeSeriesColumn<T>], persistence: Int=1000) {
        self.index = dates.map { $0.timeIntervalSince1970 }
        self.columns = columns
        self.persistence = persistence
    }
    
    public convenience init(with dates: [Date], column: TimeSeriesColumn<T>, persistence: Int=1000) {
        self.init(with: dates, columns: [column], persistence: persistence)
    }
    
    public init(with index: [Double], columns: [TimeSeriesColumn<T>], persistence: Int = 1000) {
        self.index = index
        self.columns = columns
        self.persistence = persistence
    }
    
    public convenience init(with index: [Double], column: TimeSeriesColumn<T>, persistence: Int = 1000) {
        self.init(with: index, columns: [column], persistence: persistence)
    }
    
    public convenience init(with range: ClosedRange<Date>, step: TimeInterval, fill: T = Float(0.0)) {
        let delta = range.lowerBound.distance(to: range.upperBound)
        let n = Int(delta / step)
        
        let index = vDSP.ramp(
            withInitialValue: range.lowerBound.timeIntervalSince1970,
            increment: step,
            count: n
        )
        let vec = [T](repeating: fill, count: n)
        let column = TimeSeriesColumn(vector: vec)
        self.init(with: index, column: column, persistence: n-1)
    }
    
    public var count: Int {
        index.count
    }

    public var colCount: Int {
        columns.count
    }

    public var isEmpty: Bool {
        count == 0
    }

    public var headers: [String] {
        return columns.map({ $0.name ?? $0.id.uuidString })
    }
    
    public func relativeIndex() -> [Double] {
        guard let start = index.first else { return [] }
        return index.map { $0 - start }
    }
    
    public func indexDates() -> [Date] {
        return index.map { Date(timeIntervalSince1970: $0) }
    }

    public func setPersistence(_ newValue: Int) {
        if self.persistence > newValue {
            index = Array(index.dropFirst(self.persistence - newValue))
            columns.forEach({ $0.dropFirst(self.persistence - newValue) })
        }

        self.persistence = newValue
    }
    
    public func set(names: [String]) {
        guard names.count == columns.count else { return }
        
        columns.enumerated().forEach({ $1.name = names[$0] })
    }

    public func col(at i: Int) -> TimeSeriesColumn<T> {
        guard columns.count > i else { return TimeSeriesColumn.empty }
        return columns[i]
    }
    
    public func vector(at i: Int) -> [T] {
        guard columns.count > i else { return [] }
        return columns[i].vector
    }

    public func col(with name: String) -> TimeSeriesColumn<T>? {
        return columns.first(where: { $0.name == name })
    }
    
    public func vector(with name: String) -> [T] {
        return col(with: name)?.vector ?? []
    }
    
    public func clear(rightOf idx: Int) {
        columns = Array(columns[0...idx])
    }

    public func frequencySec() -> Double {
        var result = [Double](repeating: 0.0, count: self.count-1)
        vDSP.subtract(index.dropFirst(), index.dropLast(), result: &result)
        return vDSP.mean(result)
    }
    
    public func frequencyHz() -> Double {
        var result = [Double](repeating: 0.0, count: self.count-1)
        vDSP.subtract(index.dropFirst(), index.dropLast(), result: &result)
        return 1.0 / vDSP.mean(result)
    }
    
    public func nyquistFrequencySec() -> Double {
        return frequencySec() / 2.0
    }
    
    public func nyquistFrequencyHz() -> Double {
        return frequencyHz() / 2.0
    }
    
    public func add(date: Date, values: [T]) {
        let epoch = date.timeIntervalSince1970
        self.add(epoch: epoch, values: values)
    }
    
    public func add(epoch: Double, values: [T]) {
        if columns.count == 0 {
            self.index.append(epoch)
            for value in values {
                columns.append(TimeSeriesColumn(vector: [value]))
            }
            return
        }

        if self.count > 0 {
            guard epoch >= self.index.last! else {
                return
            }
        }

        guard values.count == columns.count else {
            return
        }
        
        let shouldPop = self.count == self.persistence

        if shouldPop { self.index.remove(at: 0) }
        
        self.index.append(epoch)
        
        for (i, column) in columns.enumerated() {
            if shouldPop {
                column.dropFirst()
            }
            
            column.add(values[i])
        }
    }
    
    public func insert(column: TimeSeriesColumn<T>, at idx: Int?=nil) {
        columns.insert(column, at: idx ?? columns.count)
    }
    
    public func insert(vector: [T], name: String?=nil, idx: Int?=nil) {
        let col = TimeSeriesColumn<T>(name: name, vector: vector)
        columns.insert(col, at: idx ?? columns.count)
        
    }
    
    public func apply<U: SignalFilter>(filter: U, to colIdx: Int = 0, name: String?=nil, at destIdx: Int?=nil, after lastIndex: Double?=nil) {
        var res: [T] = []
        
        if Float.self is T.Type {
            if let lastIndex = lastIndex {
                let i = index.firstIndex(where: { $0 > lastIndex }) ?? 1 - 1
                let pre = Array(vector(at: colIdx)[...i]) as! [Float]
                let post = Array(vector(at: colIdx)[i...]) as! [Float]
                res = (pre + filter.apply(to: post)) as! [T]
            } else {
                res = filter.apply(to: vector(at: colIdx) as! [Float]) as! [T]
            }
        } else if Double.self is T.Type {
            if let lastIndex = lastIndex {
                let i = index.firstIndex(where: { $0 > lastIndex }) ?? 1 - 1
                let pre = Array(vector(at: colIdx)[...i]) as! [Double]
                let post = Array(vector(at: colIdx)[i...]) as! [Double]
                res = (pre + filter.apply(to: post)) as! [T]
            } else {
                res = filter.apply(to: vector(at: colIdx) as! [Double]) as! [T]
            }
        }
        
        insert(vector: res, name: name, idx: destIdx)
    }

    public func splitSort(criteria: [TimeSeriesSortCondition<T>]) -> [TimeSeries<T>] {
        // create empty timeseries for each criteria
        var tss: [TimeSeries<T>] = []
        criteria.forEach({ _ in tss.append(TimeSeries<T>(persistence: self.persistence)) })

        // for each criteria
//        criteria.enumerated().forEach { criteriaIdx, cond in
        for (criteriaIdx, cond) in criteria.enumerated() {
            
            // create inclusion index mask
            let sortedVecIdx: [Int] = vector(at: cond.colIdx).enumerated().compactMap({ vecIdx, val -> Int? in
                cond.filter(val) ? vecIdx : nil
            })

            // add only included indexes to new Time Series for criteria
            sortedVecIdx.forEach { sortIdx in
                tss[criteriaIdx].add(
                    epoch: index[sortIdx],
                    values: cond.include.map { vector(at: $0)[sortIdx] }
                )
            }
            
            if let names = cond.names {
                tss[criteriaIdx].columns.enumerated()
                    .forEach({ $1.name = names[$0] })
            }
        }
        tss = tss.filter({ !$0.isEmpty }) // remove everything that is empty
        return tss
    }

    public func purge(before: Date) {
        guard let cursor = index.firstIndex(where: { $0 >= before.timeIntervalSince1970 }) else {
            return
        }
        
        index = Array(index.dropFirst(cursor))
        
        columns.forEach({ $0.dropFirst(cursor) })
    }

    public func cut(before: Date, after: Date) -> TimeSeries<T> {
        guard let startCursor = index.firstIndex(where: { $0 >= before.timeIntervalSince1970 }) else {
            return TimeSeries<T>(persistence: 0)
        }

        let newIndex = Array(index.dropFirst(startCursor))
        let newColumns = columns.map({ TimeSeriesColumn(name: $0.name, vector: Array($0.vector.dropFirst(startCursor))) })

        return TimeSeries(with: newIndex, columns: newColumns, persistence: persistence)
    }
}
