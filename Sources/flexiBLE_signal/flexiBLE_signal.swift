import Foundation
import Accelerate

public struct Point<T: FloatingPoint, U: FloatingPoint> {
    public var x: T
    public var y: U
}

public enum Precision {
    case single
    case double
}

public struct flexiBLE_signal {
    public private(set) var text = "Hello, World!"

    public init() {
    }
}
