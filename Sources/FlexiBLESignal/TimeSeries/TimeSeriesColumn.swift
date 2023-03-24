//
//  TimeSeriesColumn.swift
//  
//
//  Created by Blaine Rothrock on 3/20/23.
//

import Foundation
import Accelerate

public class TimeSeriesColumn<T: FXBFloatingPoint>: Equatable, Identifiable {
    public let id: UUID
    public var name: String?
    public private(set) var vector: [T]
    
    public private(set) var filters: [any SignalFilter] = []
    
    internal init(name: String?=nil, vector: [T] = []) {
        self.id = UUID()
        self.name = name
        self.vector = vector
    }
    
    public static func == (lhs: TimeSeriesColumn<T>, rhs: TimeSeriesColumn<T>) -> Bool {
        return lhs.id == rhs.id
    }
    
    public var count: Int {
        return vector.count
    }
    
    public func add(_ val: T) {
        vector.append(executeFilters(on: val))
    }
    
    public func enable(_ filter: any SignalFilter) {
        self.filters.append(filter)
    }
    
    public func clearFilters() {
        self.filters = []
    }
    
    public func dropFirst(_ k: Int = 1) {
        vector = Array(vector.dropFirst(k))
    }
    
    private func executeFilters(on val: T) -> T {
        guard !filters.isEmpty else {
            return val
        }
        
        var v = val
        if Float.self is T.Type {
            filters.forEach({ v = $0.apply(to: v as! Float) as! T })
        } else if Double.self is T.Type {
            filters.forEach({ v = $0.apply(to: v as! Double) as! T })
        }
        
        return v
    }
}

extension TimeSeriesColumn {
    public static var empty: TimeSeriesColumn {
        return TimeSeriesColumn(vector: [])
    }
    
    public var isEmpty: Bool {
        return vector.isEmpty
    }
    
    public func apply(kernel: (T)->T) -> TimeSeriesColumn {
        let newCol = TimeSeriesColumn(vector: vector.map(kernel))
        return newCol
    }
    
    public func applyInPlace(kernel: (T)->T) {
        vector = vector.map(kernel)
    }
    
    public func vApply(kernel: ([Float], inout [Float]) -> ()) -> TimeSeriesColumn<Float> {
        let x = vector as! [Float]
        var y = [Float](repeating: 0.0, count: self.count)

        kernel(x, &y)
        return TimeSeriesColumn<Float>(vector: y)
    }
    
    public func vApplyInPlace(kernel: ([Float], inout [Float]) -> ()) {
        let x = vector as! [Float]
        var y = [Float](repeating: 0.0, count: self.count)

        kernel(x, &y)
        vector = y as! [T]
    }
    
    public func vApply(kernel: ([Double], inout [Double]) -> ()) -> TimeSeriesColumn<Double> {
        let x = vector as! [Double]
        var y = [Double](repeating: 0.0, count: self.count)

        kernel(x, &y)
        return TimeSeriesColumn<Double>(vector: y)
    }
    
    public func vApplyInPlace(kernel: ([Double], inout [Double]) -> ()) {
        let x = vector as! [Double]
        var y = [Double](repeating: 0.0, count: self.count)

        kernel(x, &y)
        vector = y as! [T]
    }
    
    public func add(_ col: TimeSeriesColumn<T>) -> TimeSeriesColumn<T> {
        if Float.self is T.Type {
            var vector = [Float](repeating: 0, count: max(vector.count, col.vector.count))
            vDSP.add(vector , col.vector as! [Float], result: &vector)
            return TimeSeriesColumn<T>(vector: vector as! [T])
        } else if Double.self is T.Type {
            var vector = [Double](repeating: 0, count: max(vector.count, col.vector.count))
            vDSP.add(vector , col.vector as! [Double], result: &vector)
            return TimeSeriesColumn<T>(vector: vector as! [T])
        }
        
        return TimeSeriesColumn.empty
    }
    
    public static func + (lhs: TimeSeriesColumn<Float>, rhs: TimeSeriesColumn<Float>) -> TimeSeriesColumn<Float> {
        var vector = [Float](repeating: 0.0, count: max(lhs.count, rhs.count))
        vDSP.add(lhs.vector , rhs.vector, result: &vector)
        return TimeSeriesColumn<Float>(vector: vector)
    }
    
    public static func + (lhs: TimeSeriesColumn<Double>, rhs: TimeSeriesColumn<Double>) -> TimeSeriesColumn<Double> {
        var vector = [Double](repeating: 0.0, count: max(lhs.count, rhs.count))
        vDSP.add(lhs.vector, rhs.vector, result: &vector)
        return TimeSeriesColumn<Double>(vector: vector)
    }
    
    public static func + (lhs: TimeSeriesColumn<Double>, rhs: TimeSeriesColumn<Float>) -> TimeSeriesColumn<Double> {
        var vector = [Double](repeating: 0.0, count: max(lhs.count, rhs.count))
        vDSP.add(lhs.vector, rhs.vector.map({Double($0)}), result: &vector)
        return TimeSeriesColumn<Double>(vector: vector)
    }
    
    public static func + (lhs: TimeSeriesColumn<Float>, rhs: TimeSeriesColumn<Double>) -> TimeSeriesColumn<Double> {
        var vector = [Double](repeating: 0.0, count: max(lhs.count, rhs.count))
        vDSP.add(lhs.vector.map({ Double($0) }), rhs.vector.map({Double($0)}), result: &vector)
        return TimeSeriesColumn<Double>(vector: vector)
    }
    
    public static func - (lhs: TimeSeriesColumn<Float>, rhs: TimeSeriesColumn<Float>) -> TimeSeriesColumn<Float> {
        var vector = [Float](repeating: 0.0, count: max(lhs.count, rhs.count))
        vDSP.subtract(lhs.vector, rhs.vector, result: &vector)
        return TimeSeriesColumn<Float>(vector: vector)
    }
    
    public static func - (lhs: TimeSeriesColumn<Double>, rhs: TimeSeriesColumn<Double>) -> TimeSeriesColumn<Double> {
        var vector = [Double](repeating: 0.0, count: max(lhs.count, rhs.count))
        vDSP.subtract(lhs.vector, rhs.vector, result: &vector)
        return TimeSeriesColumn<Double>(vector: vector)
    }
    
    public static func * (lhs: TimeSeriesColumn<Float>, rhs: TimeSeriesColumn<Float>) -> TimeSeriesColumn<Float> {
        var vector = [Float](repeating: 0.0, count: max(lhs.count, rhs.count))
        vDSP.multiply(lhs.vector, rhs.vector, result: &vector)
        return TimeSeriesColumn<Float>(vector: vector)
    }
    
    public static func * (lhs: TimeSeriesColumn<Double>, rhs: TimeSeriesColumn<Double>) -> TimeSeriesColumn<Double> {
        var vector = [Double](repeating: 0.0, count: max(lhs.count, rhs.count))
        vDSP.multiply(lhs.vector, rhs.vector, result: &vector)
        return TimeSeriesColumn<Double>(vector: vector)
    }
    
    public static func / (lhs: TimeSeriesColumn<Float>, rhs: TimeSeriesColumn<Float>) -> TimeSeriesColumn<Float> {
        var vector = [Float](repeating: 0.0, count: max(lhs.count, rhs.count))
        vDSP.divide(lhs.vector, rhs.vector, result: &vector)
        return TimeSeriesColumn<Float>(vector: vector)
    }
    
    public static func / (lhs: TimeSeriesColumn<Double>, rhs: TimeSeriesColumn<Double>) -> TimeSeriesColumn<Double> {
        var vector = [Double](repeating: 0.0, count: max(lhs.count, rhs.count))
        vDSP.divide(lhs.vector, rhs.vector, result: &vector)
        return TimeSeriesColumn<Double>(vector: vector)
    }
}
