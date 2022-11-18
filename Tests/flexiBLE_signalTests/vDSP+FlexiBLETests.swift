//
// Created by Blaine Rothrock on 11/15/22.
//

import Foundation
import XCTest
import Accelerate
import Collections
@testable import flexiBLE_signal

final class vDSPFlexiBLETests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSinc() throws {
        var x = [Double](repeating: 5.0, count: 100)
        var y = [Double](repeating: 0.0, count: 100)

        vDSP.sinc(x, result: &y)

        print(y)
    }

}