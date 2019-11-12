//
//  Utils.swift
//  BezierPod
//
//  Created by Takuto Nakamura on 2019/05/22.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import CoreGraphics

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
    
    var scalar: CGFloat {
        return (pow(self.x, 2.0) + pow(self.y, 2.0)).squareRoot()
    }
    
    func length(from: CGPoint) -> CGFloat {
        return (self - from).scalar
    }
    
    func innerProduct(_ v: CGPoint) -> (value: CGFloat, theta: CGFloat) {
        let value: CGFloat = self.x * v.x + self.y * v.y
        return (value, acos(value / (self.scalar * v.scalar)))
    }
    
    func exteriorAngle(_ v: CGPoint) -> CGFloat {
        let op: CGFloat = self.x * v.y - self.y * v.x
        let theta = self.innerProduct(v).theta
        return op > 0 ? theta : -theta
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

public extension CGRect {
    var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
    
    func strictIntersects(_ rect2: CGRect) -> Bool {
        if self.intersects(rect2) {
            return true
        }
        if self.contains(CGPoint(x: rect2.minX, y: rect2.minY))
            || self.contains(CGPoint(x: rect2.minX, y: rect2.maxY))
            || self.contains(CGPoint(x: rect2.maxX, y: rect2.minY))
            || self.contains(CGPoint(x: rect2.maxX, y: rect2.maxY)) {
            return true
        }
        return false
    }
}
