//
//  Line.swift
//  BezierPod
//
//  Created by Takuto Nakamura on 2019/10/12.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import Cocoa

typealias LinePair = (left: Line, right: Line)

public class Line: Bezier {
    
    public init(p1: NSPoint, p2: NSPoint) {
        super.init(points: [p1, p1, p2, p2])
    }
    
    public init(p: NSPoint, v: NSPoint, length: CGFloat) {
        let len: CGFloat = v.length(from: p)
        if len == 0.0 {
            fatalError("Error: p and v must be different points.")
        }
        let t: CGFloat = length / len
        let newP2 = (1.0 - t) * p + t * v
        super.init(points: [p, p, newP2, newP2])
    }
    
    public func updateSelf(_ line: Line) {
        self.points = line.points
    }
    
    public var path: NSBezierPath {
        let path = NSBezierPath()
        path.move(to: p1)
        path.line(to: p2)
        return path
    }
    
    override public var description: String {
        return "p1: \(p1), p2: \(p2)"
    }
    
    override var center: NSPoint {
        return (p1 + p2) / 2.0
    }
    
    // ★★★ Unique Method ★★★
    override func compute(_ t: CGFloat) -> NSPoint {
        return (1.0 - t) * p1 + t * p2
    }
    
    func backCompute(_ p: NSPoint) -> CGFloat? {
        let tx: CGFloat = (p.x - p1.x) / (p2.x - p1.x)
        let ty: CGFloat = (p.y - p1.y) / (p2.y - p1.y)
        if approximately(tx - ty, 0.0) {
            return (tx + ty) / 2.0
        }
        return nil
    }
    
    var lineLength: CGFloat {
        return p1.length(from: p2)
    }
    
    func offset(_ d: CGFloat) -> Line {
        let diff: NSPoint = p2 - p1
        let len: CGFloat = diff.scalar
        if len == 0.0 { return self }
        let normal: NSPoint = d * NSPoint(x: diff.y / len, y: -diff.x / len)
        return Line(p1: p1 + normal, p2: p2 + normal)
    }

    var bbox: Bbox {
        let minX = min(p1.x, p2.x)
        let minY = min(p1.y, p2.y)
        let maxX = max(p1.x, p2.x)
        let maxY = max(p1.y, p2.y)
        return Bbox(MinMax(minX, maxX, (minX + maxX) / 2.0, maxX - minX),
                    MinMax(minY, maxY, (minY + maxY) / 2.0, maxY - minY))
    }
    
    var reversed: Line {
        return Line(p1: p2, p2: p1)
    }
    
    func extend(_ left: CGFloat, _ right: CGFloat) -> Line {
        let len: CGFloat = lineLength
        if len == 0.0 { return self }
        let newP1 = (1.0 + left / len) * p1 - (left / len) * p2
        let newP2 = (1.0 + right / len) * p2 - (right / len) * p1
        return Line(p1: newP1, p2: newP2)
    }
    
    func overlaps(_ line: Line) -> Bool {
        let abx: CGFloat = self.p1.x - self.p2.x
        let aby: CGFloat = self.p1.y - self.p2.y
        
        let cdx: CGFloat = line.p1.x - line.p2.x
        let cdy: CGFloat = line.p1.y - line.p2.y
        
        let a: CGFloat = cdx * (self.p1.y - line.p1.y) + cdy * (line.p1.x - self.p1.x)
        let b: CGFloat = cdx * (self.p2.y - line.p1.y) + cdy * (line.p1.x - self.p2.x)
        let c: CGFloat = abx * (line.p1.y - self.p1.y) + aby * (self.p1.x - line.p1.x)
        let d: CGFloat = abx * (line.p2.y - self.p1.y) + aby * (self.p1.x - line.p2.x)
        
        return a * b < 0.0 && c * d < 0.0
    }
    
    // line intersects
    func intersect(_ line: Line) -> Intersect? {
        if !self.overlaps(line) { return nil }
        var t: CGFloat = 0.0
        var s: CGFloat = 0.0
        let dx: CGFloat = line.p2.x - line.p1.x
        let dy: CGFloat = line.p2.y - line.p1.y
        if dx == 0.0 && dy == 0.0 {
            return nil
        } else if dx == 0.0 {
            t = (line.p1.x - p1.x) / (p2.x - p1.x)
            s = (t * (p2.y - p1.y) + (p1.y - line.p1.y)) / dy
        } else if dy == 0.0 {
            t = (line.p1.y - p1.y) / (p2.y - p1.y)
            s = (t * (p2.x - p1.x) + (p1.x - line.p1.x)) / dx
        } else {
            let u: CGFloat = (p1.y - line.p1.y) / dy - (p1.x - line.p1.x) / dx
            let v: CGFloat = (p2.x - p1.x) / dx - (p2.y - p1.y) / dy
            if v == 0.0 { return nil } // When two line segments overlap
            t = u / v
            s = (t * (p2.x - p1.x) + (p1.x - line.p1.x)) / dx
        }
        if !between(t, 0.0, 1.0) || !between(s, 0.0, 1.0) {
            return nil
        }
        return Intersect(tSelf: t, tOther: s)
    }
    
    // curve intersects
    func intersects(_ curve: Curve) -> [Intersect]? {
        let result: [Intersect] = roots(curve.points, self).compactMap { (v) -> Intersect? in
            if !between(v, 0.0, 1.0) { return nil }
            let p: NSPoint = curve.compute(v)
            guard let t: CGFloat = backCompute(p) else { return nil }
            if !between(t, 0.0, 1.0) { return nil }
            return Intersect(tSelf: t, tOther: v)
        }
        if result.isEmpty { return nil }
        return result
    }
    
    func split(_ t: CGFloat) -> LinePair {
        let p: NSPoint = (1.0 - t) * p1 + t * p2
        let left = Line(p1: p1, p2: p)
        let right = Line(p1: p, p2: p2)
        return LinePair(left, right)
    }
    
    func split(_ t1: CGFloat, _ t2: CGFloat) -> Line {
        if t1 == 0.0 {
            return split(t2).left
        }
        if t2 == 1.0 {
            return split(t1).right
        }
        return Line(p1: (1.0 - t1) * p1 + t1 * p2,
                    p2: (1.0 - t2) * p1 + t2 * p2)
    }
    
    func split(_ via: NSPoint) -> LinePair {
        return LinePair(Line(p1: p1, p2: via), Line(p1: via, p2: p2))
    }

    override func distance(from q: NSPoint) -> (value: CGFloat, t: CGFloat) {
        let dx: CGFloat = p2.x - p1.x
        let dy: CGFloat = p2.y - p1.y
        if dx == 0.0 && dy == 0.0 {
            return (q.length(from: p1), 0.0)
        } else if dx == 0.0 {
            let t: CGFloat = (q.y - p1.y) / (p2.y - p1.y)
            if t < 0.0 {
                return (q.length(from: p1), 0.0)
            } else if 1.0 < t {
                return (q.length(from: p2), 1.0)
            }
            return (abs(p1.x - q.x), t)
        } else if dy == 0.0 {
            let t: CGFloat = (q.x - p1.x) / (p2.x - p1.x)
            if t < 0.0 {
                return (q.length(from: p1), 0.0)
            } else if 1.0 < t {
                return (q.length(from: p2), 1.0)
            }
            return (abs(p1.y - q.y), t)
        }
        let u: CGFloat = (p1.x - q.x) / dy + (p1.y - q.y) / dx
        let v: CGFloat = (p1.x - p2.x) / dy + (p1.y - p2.y) / dx
        let t: CGFloat = u / v
        if t < 0.0 {
            return (q.length(from: p1), 0.0)
        } else if 1.0 < t {
            return (q.length(from: p2), 1.0)
        }
        let Q = NSPoint(x: q.x - (1.0 - t) * p1.x - t * p2.x,
                        y: q.y - (1.0 - t) * p1.y - t * p2.y)
        return (Q.scalar, t)
    }
    
    func distance(between line: Line) -> CGFloat {
        if let _ = intersect(line) {
            return 0.0
        }
        var ds = [CGFloat]()
        ds.append(distance(from: line.p1).value)
        ds.append(distance(from: line.p2).value)
        ds.append(line.distance(from: p1).value)
        ds.append(line.distance(from: p2).value)
        return ds.min()!
    }
    
    // roughly
    func distance(between curve: Curve) -> CGFloat {
        if curve.overlaps(self), let _ = intersects(curve) {
            return 0.0
        }
        var d: CGFloat = curve.distance(from: p1).value
        // 0.1 is search density
        let limit = Int(0.1 * lineLength)
        for n in (1 ... limit) {
            let t = CGFloat(n) / CGFloat(limit)
            d = min(d, curve.distance(from: compute(t)).value)
        }
        return d
    }
    
}
