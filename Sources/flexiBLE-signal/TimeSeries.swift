//
//  TimeSeries.swift
//  
//
//  Created by Blaine Rothrock on 10/17/22.
//

import Foundation
import Accelerate

struct TimeSeries<T: FloatingPoint> {
    public private(set) var index: Array<Double>
    public private(set) var vecs: [[T]]
    public private(set) var persistance: Int
    
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
}
