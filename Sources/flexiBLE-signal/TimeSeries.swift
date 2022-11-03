//
//  TimeSeries.swift
//  
//
//  Created by Blaine Rothrock on 10/17/22.
//

import Foundation
import Accelerate

public protocol FXBFloatingPoint { }
extension Float: FXBFloatingPoint { }
extension Double: FXBFloatingPoint { }

public struct TimeSeries<T: FXBFloatingPoint> {
    public private(set) var index: Array<Double>

    private var vecs: [[T]]
    private var vecNames: [String]

    public private(set) var persistence: Int

    public enum Operation {
        case add
        case subtract
        case multiply
        case divide
    }
    
    public enum FilterType {
        case minMaxScaling
        case zscore
        case demean
        case movingAverage(window: Int)
    }
    
    public init(persistence: Int) {
        self.index = []
        self.vecs = []
        self.vecNames = []
        self.persistence = persistence
    }
    
    public init(with dates: [Date], vecs: [[T]], vecNames: [String]?=nil, persistence: Int=1000) {
        self.index = dates.map { $0.timeIntervalSince1970 }
        self.vecs = vecs
        self.persistence = persistence
        self.vecNames = vecNames == nil ? Array(0..<vecs.count).map({ String($0) }) : vecNames!
    }
    
    public init(with dates: [Date], vec: [T], vecNames: [String]?=nil, persistence: Int=1000) {
        self.init(with: dates, vecs: [vec], vecNames: vecNames, persistence: persistence)
    }
    
    public init(with index: [Double], vecs: [[T]], vecNames: [String]?=nil, persistence: Int = 1000) {
        self.index = index
        self.vecs = vecs
        self.persistence = persistence
        self.vecNames = vecNames == nil ? Array(0..<vecs.count).map({ String($0) }) : vecNames!
    }
    
    public init(with index: [Double], vec: [T], vecNames: [String]? = nil, persistence: Int = 1000) {
        self.init(with: index, vecs: [vec], vecNames: vecNames, persistence: persistence)
    }
    
    public init(with range: ClosedRange<Date>, step: TimeInterval, fill: T = Float(0.0)) {
        let delta = range.lowerBound.distance(to: range.upperBound)
        let n = Int(delta / step)
        
        let index = vDSP.ramp(
            withInitialValue: range.lowerBound.timeIntervalSince1970,
            increment: step,
            count: n
        )
        let vec = [T](repeating: fill, count: n)
        self.init(with: index, vec: vec, persistence: n-1)
    }
    
    public var count: Int {
        index.count
    }

    public var colCount: Int {
        vecs.count
    }

    public var isEmpty: Bool {
        count == 0
    }

    public var colNames: [String?] {
        return vecNames
    }
    
    public func relativeIndex() -> [Double] {
        guard let start = index.first else { return [] }
        return index.map { $0 - start }
    }
    
    public func indexDates() -> [Date] {
        return index.map { Date(timeIntervalSince1970: $0) }
    }

    public mutating func setPersistence(_ newValue: Int) {
        if self.persistence > newValue {
            index = Array(index.dropFirst(self.persistence - newValue))
            for i in 0..<vecs.count {
                vecs[i] = Array(vecs[i].dropFirst(self.persistence - newValue))
            }
        }

        self.persistence = newValue
    }

    public func col(at i: Int) -> [T] {
        guard vecs.count > i else { return [] }
        return vecs[i]
    }

    public func col(with name: String) -> [T] {
        guard let nameIdx = vecNames.firstIndex(of: name) else { return [] }
        return vecs[nameIdx]
    }

    public mutating func setColNames(_ names: [String]) {
        guard names.count == vecs.count else { return }
        vecNames = names
    }

    public mutating func setColName(for idx: Int, name: String) {
        vecNames[idx] = name
    }

    public func frequency() -> Double {
        var result = [Double](repeating: 0.0, count: self.count-1)
        vDSP.subtract(index.dropFirst(), index.dropLast(), result: &result)
        return vDSP.mean(result)
    }
    
    public mutating func add(date: Date, values: [T]) {
        let epoch = date.timeIntervalSince1970
        self.add(epoch: epoch, values: values)
    }
    
    public mutating func add(epoch: Double, values: [T]) {
        if vecs.count == 0 {
            for _ in values.enumerated() {
                vecs.append([T]())
                vecNames.append(String(vecs.count))
            }
        }

        if self.count > 0 {
            guard epoch >= self.index.last! else {
                return
            }
        }

        guard values.count == vecs.count else {
            return
        }
        let shouldPop = self.count == self.persistence

        if shouldPop { self.index.remove(at: 0) }
        self.index.append(epoch)
        for (i, _) in vecs.enumerated() {
            if shouldPop { vecs[i].remove(at: 0) }
            vecs[i].append(values[i])
        }
    }
    
    public mutating func apply(colIdx: Int, vec: [T], op: Operation, name: String?=nil) {
        if T.self is Float.Type {
            var result = [Float](repeating: 0.0, count: self.count)
            let a = col(at: colIdx) as! [Float]
            switch op {
            case .add: vDSP.add(a, vec as! [Float], result: &result)
            case .subtract: vDSP.subtract(a, vec as! [Float], result: &result)
            case .multiply: vDSP.multiply(a, vec as! [Float], result: &result)
            case .divide: vDSP.divide(a, vec as! [Float], result: &result)
            }
            
            vecs.append(result as! [T])
            vecNames.append(name==nil ? String(vecs.count) : name!)
        } else if T.self is Double.Type {
            var result = [Double](repeating: 0.0, count: self.count)
            let a = col(at: colIdx) as! [Double]
            switch op {
            case .add: vDSP.add(a, vec as! [Double], result: &result)
            case .subtract: vDSP.subtract(a, vec as! [Double], result: &result)
            case .multiply: vDSP.multiply(a, vec as! [Double], result: &result)
            case .divide: vDSP.divide(a, vec as! [Double], result: &result)
            }
            
            vecs.append(result as! [T])
            vecNames.append(name==nil ? String(vecs.count) : name!)
        }
    }
    
    public mutating func apply(colA: Int, colB: Int, op: Operation, name: String?=nil) {
        if Float.self is T {
            var result = [Float](repeating: 0.0, count: self.count)
            let a = col(at: colA) as! [Float]
            let b = col(at: colB) as! [Float]
            switch op {
            case .add: vDSP.add(a, b, result: &result)
            case .subtract: vDSP.subtract(a, b, result: &result)
            case .multiply: vDSP.multiply(a, b, result: &result)
            case .divide: vDSP.divide(a, b, result: &result)
            }
            
            vecs.append(result as! [T])
            vecNames.append(name==nil ? String(vecs.count) : name!)
        } else if T.self is Double.Type {
            var result = [Double](repeating: 0.0, count: self.count)
            let a = col(at: colA) as! [Double]
            let b = col(at: colB) as! [Double]
            switch op {
            case .add: vDSP.add(a, b, result: &result)
            case .subtract: vDSP.subtract(a, b, result: &result)
            case .multiply: vDSP.multiply(a, b, result: &result)
            case .divide: vDSP.divide(a, b, result: &result)
            }
            
            vecs.append(result as! [T])
            vecNames.append(name==nil ? String(vecs.count) : name!)
        }
    }
    
    public mutating func apply(filter: FilterType, to colIdx: Int = 0, name: String?=nil) {
        if Float.self is T.Type {
            let x = self.col(at: colIdx) as! [Float]
            var result = [Float](repeating: 0.0, count: self.count)

            switch filter {
            case .minMaxScaling: Filter.minMax(x: x, result: &result)
            case .zscore: Filter.zscore(x: x, result: &result)
            case .demean: Filter.demean(x: x, result: &result)
            case .movingAverage(let w):
                Filter.movingAverage(x: x, window: w, result: &result)
            }

            vecs.append(result as! [T])
            vecNames.append(name==nil ? String(vecs.count) : name!)
        } else if Double.self is T.Type {
            let x = self.col(at: colIdx) as! [Double]
            var result = [Double](repeating: 0.0, count: self.count)

            switch filter {
            case .minMaxScaling: Filter.minMax(x: x, result: &result)
            case .zscore: Filter.zscore(x: x, result: &result)
            case .demean: Filter.demean(x: x, result: &result)
            case .movingAverage(let w): Filter.movingAverage(x: x, window: w, result: &result)
            }

            vecs.append(result as! [T])
            vecNames.append(name==nil ? String(vecs.count) : name!)
        }
    }

    public mutating func apply(colIdx: Int, kernel: @escaping (T)->T, name: String?=nil) {
        guard colIdx < colCount else { return }
        vecs.append(vecs[colIdx].map(kernel))
        vecNames.append(name==nil ? String(vecs.count) : name!)
    }

    public func splitSort(criteria: [TimeSeriesSortCondition<T>]) -> [TimeSeries<T>] {
        var tss = [TimeSeries<T>](
                repeating: TimeSeries<T>(persistence: self.persistence),
                count: criteria.count
        )

        criteria.enumerated().forEach { criteriaIdx, cond in
            let sortedVecIdx: [Int] = vecs[cond.colIdx].enumerated().compactMap({ vecIdx, val -> Int? in
                cond.filter(val) ? vecIdx : nil
            })

            sortedVecIdx.forEach { sortIdx in
                tss[criteriaIdx].add(
                    epoch: index[sortIdx],
                    values: cond.include.map { vecs[$0][sortIdx] }
                )
            }
            if let names = cond.names {
                tss[criteriaIdx].setColNames(names)
            }
        }
        tss = tss.filter({ !$0.isEmpty }) // remove everything that is empty
        return tss
    }

    public mutating func purge(before: Date) {
        guard let cursor = index.firstIndex(where: { $0 >= before.timeIntervalSince1970 }) else {
            return
        }
        index = Array(index.dropFirst(cursor))
        Array(0..<vecs.count).forEach({
            vecs[$0] = Array(vecs[$0].dropFirst(cursor))
        })
    }

    public func cut(before: Date, after: Date) -> TimeSeries<T> {
        guard let startCursor = index.firstIndex(where: { $0 >= before.timeIntervalSince1970 }) else {
            return TimeSeries<T>(persistence: 0)
        }

        var newIndex = Array(index.dropFirst(startCursor))
        var newVecs = vecs.map({ Array($0.dropFirst(startCursor)) })

//        let endIdx = newIndex.lastIndex(where: { $0 >= after.timeIntervalSince1970 }) ?? newIndex.count - 1
//        let endCursor = newIndex.count - 1 - endIdx
//
//        newIndex = Array(newIndex.dropLast(endCursor))
//        newVecs = newVecs.map({ Array($0.dropLast(endCursor)) })
        return TimeSeries(with: newIndex, vecs: newVecs, persistence: persistence)
    }
}
