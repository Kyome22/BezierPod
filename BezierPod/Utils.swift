//
//  Utils.swift
//  BezierPod
//
//  Created by Takuto Nakamura on 2019/05/22.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import Cocoa

infix operator >>> : BitwiseShiftPrecedence
public func >>> (lhs: Int, rhs: Int) -> Int {
    Int(bitPattern: UInt(bitPattern: lhs) >> UInt(rhs))
}

public func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

public func += (left: inout CGPoint, right: CGPoint) {
    left = left + right
}

public prefix func - (fraction: CGPoint) -> CGPoint {
    return CGPoint(x: -fraction.x, y: -fraction.y)
}

public func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

public func -= (left: inout CGPoint, right: CGPoint) {
    left = left - right
}

public func * (left: CGFloat, right: CGPoint) -> CGPoint {
    return CGPoint(x: left * right.x, y: left * right.y)
}

public func * (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: right * left.x, y: right * left.y)
}

public func *= (left: inout CGPoint, right: CGFloat) {
    left = left * right
}

public func / (left: CGPoint, right: CGFloat) -> CGPoint {
    assert(right != 0, "divide by zero")
    return CGPoint(x: left.x / right, y: left.y / right)
}

public func /= (left: inout CGPoint, right: CGFloat) {
    assert(right != 0, "divide by zero")
    left = left / right
}


public extension CGPoint {
    init(_ const: CGFloat) {
        self.init(x: const, y: const)
    }
    func length(from: CGPoint) -> CGFloat {
        return (pow(self.x - from.x, 2.0) + pow(self.y - from.y, 2.0)).squareRoot()
    }

    func radian(from: CGPoint) -> CGFloat {
        return atan2(self.y - from.y, self.x - from.x)
    }
    
    func innerProduct(_ v: NSPoint) -> (value: CGFloat, theta: CGFloat) {
        let value: CGFloat = self.x * v.x + self.y * v.y
        let A: CGFloat = (pow(self.x, 2.0) + pow(self.y, 2.0)).squareRoot()
        let B: CGFloat = (pow(v.x, 2.0) + pow(v.y, 2.0)).squareRoot()
        return (value, acos(value / (A * B)))
    }
    
    func outerProduct(_ v: NSPoint) -> (value: CGFloat, theta: CGFloat) {
        let value: CGFloat = self.x * v.y - self.y * v.x
        let A: CGFloat = (pow(self.x, 2.0) + pow(self.y, 2.0)).squareRoot()
        let B: CGFloat = (pow(v.x, 2.0) + pow(v.y, 2.0)).squareRoot()
        return (value, asin(value / (A * B)))
    }
    
    func exteriorAngle(_ v: NSPoint) -> CGFloat {
        let op: CGFloat = self.x * v.y - self.y * v.x
        let ip = self.innerProduct(v)
        return op > 0 ? ip.theta : -ip.theta
    }
    
}


public func + (left: CGSize, right: CGSize) -> CGSize {
    return CGSize(width: left.width + right.width, height: left.height + right.height)
}

public func += (left: inout CGSize, right: CGSize) {
    left = left + right
}

public func - (left: CGSize, right: CGSize) -> CGSize {
    return CGSize(width: left.width - right.width, height: left.height - right.height)
}

public func -= (left: inout CGSize, right: CGSize) {
    left = left - right
}

public func * (left: CGFloat, right: CGSize) -> CGSize {
    return CGSize(width: left * right.width, height: left * right.height)
}

public func * (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: right * left.width, height: right * left.height)
}

public func *= (left: inout CGSize, right: CGFloat) {
    left = left * right
}

public func / (left: CGSize, right: CGFloat) -> CGSize {
    assert(right != 0, "divide by zero")
    return CGSize(width: left.width / right, height: left.height / right)
}

public func /= (left: inout CGSize, right: CGFloat) {
    assert(right != 0, "divide by zero")
    left = left / right
}

public extension CGSize {
    init(_ const: CGFloat) {
        self.init(width: const, height: const)
    }
}
