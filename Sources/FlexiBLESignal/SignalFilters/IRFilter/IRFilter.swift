//
//  IRFilter.swift
//  
//
//  Created by Blaine Rothrock on 3/17/23.
//

import Foundation

public protocol IRFilter<FP>: SignalFilter {
    associatedtype FP = FXBFloatingPoint
    
    var kernel: [FP]? { get }
}
