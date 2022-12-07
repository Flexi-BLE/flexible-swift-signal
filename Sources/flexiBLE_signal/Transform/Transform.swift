//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 12/7/22.
//

import Foundation


//protocol Transform {
//    var src: [Int] { get }
//    var dest: Int { get }
//}

public class SignalFilterTransform {
    public var src: Int
    public var dest: Int
    
    public var filter: any SignalFilter
    
    init(src: Int, dest: Int, filter: any SignalFilter) {
        self.src = src
        self.dest = dest
        self.filter = filter
    }
    
    func apply<T: FXBFloatingPoint>(to ts: inout TimeSeries<T>) {
        ts.apply(filter: filter, to: src, name: nil)
        self.dest = ts.count
    }
}

