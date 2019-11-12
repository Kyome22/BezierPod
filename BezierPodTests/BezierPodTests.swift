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
    
    func testMeu() {
        let points = [NSPoint(x: 184.92578125, y: 306.47265625),
                        NSPoint(x: 64.1484375,   y: 103.9140625),
                        NSPoint(x: 349.3828125,  y: 343.625),
                        NSPoint(x: 396.18359375, y: 82.67578125)]
        let curve = Curve(points: points)
        let line = Line(p1: NSPoint(x: 396.18359375, y: 82.67578125),
                        p2: NSPoint(x: 125.9140625,  y: 335.80859375))
        let roots = curve.roots(points, line)
        roots.forEach { (t) in
            Swift.print(curve.compute(t))
        }
    }
    
    func testGomi() {
        let pathA = NSBezierPath(rect: NSRect(x: 0, y: 0, width: 50, height: 50))
        let pathB = NSBezierPath(rect: NSRect(x: 5, y: 5, width: 40, height: 40))
        Swift.print(pathA.bounds.intersects(pathB.bounds))
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
