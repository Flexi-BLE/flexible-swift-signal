//
//  TimeSeries.swift
//  
//
//  Created by Blaine Rothrock on 10/17/22.
//

import Foundation
import Accelerate

protocol FXBFloatingPoint { }
extension Float: FXBFloatingPoint { }
extension Double: FXBFloatingPoint { }

struct TimeSeries<T: FXBFloatingPoint> {
    public private(set) var index: Array<Double>
    public private(set) var vecs: [[T]]
    public private(set) var persistance: Int
    
    enum Operation {
        case add
        case substract
        case multiply
        case divide
    }
    
    enum Filter {
        case zscore
    }
    
    public init(persistence: Int) {
        self.index = []
        self.vecs = []
        self.persistance = persistence
    }
    
    public init(with dates: [Date], vecs: [[T]], persistance: Int=1000) {
        self.index = dates.map { $0.timeIntervalSince1970 }
        self.vecs = vecs
        self.persistance = 1000
    }
    
    public init(with dates: [Date], vec: [T], persistance: Int=1000) {
        self.init(with: dates, vecs: [vec], persistance: persistance)
    }
    
    public init(with index: [Double], vecs: [[T]], persistance: Int = 1000) {
        self.index = index
        self.vecs = vecs
        self.persistance = 1000
    }
    
    public init(with index: [Double], vec: [T], persistance: Int = 1000) {
        self.init(with: index, vecs: [vec], persistance: persistance)
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
        self.init(with: index, vec: vec, persistance: n)
    }
    
    public var count: Int {
        return index.count
    }
    
    public func relativeIndex() -> [Double] {
        guard let start = index.first else { return [] }
        return index.map { $0 - start }
    }
    
    public func col(at i: Int) -> [T] {
        guard vecs.count > i else { return [] }
        return vecs[i]
    }
    
    public func frequency() -> Double {
        var result = [Double](repeating: 0.0, count: self.count-1)
        vDSP.subtract(index.dropFirst(), index.dropLast(), result: &result)
        return vDSP.mean(result)
    }
    
    public mutating func add(date: Date, values: [T]) {
        guard values.count == vecs.count else { return }
        
        self.index.append(date.timeIntervalSince1970)
        for (i, _) in vecs.enumerated() {  vecs[i].append(values[i]) }
    }
    
    public mutating func add(epoch: Double, values: [T]) {
        if vecs.count == 0 {
            for _ in values.enumerated() {
                vecs.append([T]())
            }
        }
        
        guard values.count == vecs.count else { return }
        
        self.index.append(epoch)
        for (i, _) in vecs.enumerated() { vecs[i].append(values[i]) }
    }
    
    public mutating func apply(colIdx: Int, vec: [T], op: Operation) {
        if T.self is Float.Type {
            var result = [Float](repeating: 0.0, count: self.count)
            let a = col(at: colIdx) as! [Float]
            switch op {
            case .add: vDSP.add(a, vec as! [Float], result: &result)
            case .substract: vDSP.subtract(a, vec as! [Float], result: &result)
            case .multiply: vDSP.multiply(a, vec as! [Float], result: &result)
            case .divide: vDSP.divide(a, vec as! [Float], result: &result)
            }
            
            vecs.append(result as! [T])
        } else if T.self is Double.Type {
            var result = [Double](repeating: 0.0, count: self.count)
            let a = col(at: colIdx) as! [Double]
            switch op {
            case .add: vDSP.add(a, vec as! [Double], result: &result)
            case .substract: vDSP.subtract(a, vec as! [Double], result: &result)
            case .multiply: vDSP.multiply(a, vec as! [Double], result: &result)
            case .divide: vDSP.divide(a, vec as! [Double], result: &result)
            }
            
            vecs.append(result as! [T])
        }
    }
    
    public mutating func apply(colA: Int, colB: Int, op: Operation) {
        if Float.self is T {
            var result = [Float](repeating: 0.0, count: self.count)
            let a = col(at: colA) as! [Float]
            let b = col(at: colB) as! [Float]
            switch op {
            case .add: vDSP.add(a, b, result: &result)
            case .substract: vDSP.subtract(a, b, result: &result)
            case .multiply: vDSP.multiply(a, b, result: &result)
            case .divide: vDSP.divide(a, b, result: &result)
            }
            
            vecs.append(result as! [T])
        } else if Double.self is T {
            var result = [Double](repeating: 0.0, count: self.count)
            let a = col(at: colA) as! [Double]
            let b = col(at: colB) as! [Double]
            switch op {
            case .add: vDSP.add(a, b, result: &result)
            case .substract: vDSP.subtract(a, b, result: &result)
            case .multiply: vDSP.multiply(a, b, result: &result)
            case .divide: vDSP.divide(a, b, result: &result)
            }
            
            vecs.append(result as! [T])
        }
    }
    
    public mutating func apply(filter: Filter, to colIdx: Int = 0) {
        switch filter {
        case .zscore:
            
        }
    }
}
