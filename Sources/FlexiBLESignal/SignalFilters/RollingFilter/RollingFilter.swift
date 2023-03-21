//
//  RollingFilter.swift
//  
//
//  Created by Blaine Rothrock on 3/17/23.
//

import Foundation
import Accelerate

public protocol RollingFilter<FP>: SignalFilter {
    associatedtype FP = FXBFloatingPoint
    
    
}
