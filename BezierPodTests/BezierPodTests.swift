//
//  BezierPodTests.swift
//  BezierPodTests
//
//  Created by Takuto Nakamura on 2019/10/20.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import XCTest
//@testable import BezierPod

class BezierPodTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCurveDistance() {
        let b = Curve(points: [CGPoint(x: 5, y: 5), CGPoint(x: 15, y: 60), CGPoint(x: 35, y: -45), CGPoint(x: 50, y: 15)])
        let p = b.compute(0.34)
        let l = b.distance(from: p)
        Swift.print(String(format: "%08lf", l.value))
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
