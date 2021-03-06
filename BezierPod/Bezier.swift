//
//  Bezier.swift
//  BezierPod
//
//  Created by Takuto Nakamura on 2019/10/12.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import CoreGraphics

fileprivate let tau = 2 * CGFloat.pi

public struct Intersect {
    public private(set) var tSelf: CGFloat
    public private(set) var tOther: CGFloat
}

public class Bezier {
    // fromPoint, controlPoint1, controlPoint2, toPoint
    // There are absolutely two control points
    var points: [CGPoint]
    var center: CGPoint { return .zero }
    var bounds: CGRect { return .zero }
    public var p1: CGPoint { return points[0] }
    public var c1: CGPoint { return points[1] }
    public var c2: CGPoint { return points[2] }
    public var p2: CGPoint { return points[3] }
    public var description: String { return "" }
    
    init(points: [CGPoint]) {
        if points.count != 4 {
            fatalError("Error: Bezier needs 4 points.")
        }
        self.points = points
    }
    
    func compute(_ t: CGFloat) -> CGPoint {
        return CGPoint.zero
    }
    
    func distance(from q: CGPoint) -> (value: CGFloat, t: CGFloat) {
        return (0.0, 0.0)
    }
    
    func approximately(_ a: CGFloat, _ b: CGFloat, _ epsilon: CGFloat = 0.000001) -> Bool {
        return abs(a - b) <= epsilon
    }
    
    func between(_ v: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> Bool {
        if approximately(v, minV) || approximately(v, maxV) {
            return false
        }
        return (minV ... maxV).contains(v)
    }
    
    func overlaps(_ bezier: Bezier) -> Bool {
        return bounds.intersects(bezier.bounds)
    }
    
    func selfIntersects() -> [Intersect]? {
        if let curve = self as? Curve {
            return curve.intersects()
        }
        return nil
    }
    
    func intersects(with bezier: Bezier) -> [Intersect]? {
        switch (self, bezier) {
        case let (lineS as Line, lineO as Line):
            if let intersect = lineS.intersect(lineO) {
                return [intersect]
            }
            return nil
        case let (lineS as Line, curveO as Curve):
            return lineS.intersects(curveO)
        case let (curveS as Curve, lineO as Line):
            return curveS.intersects(lineO)
        case let (curveS as Curve, curveO as Curve):
            return curveS.intersects(curveO)
        default:
            return nil
        }
    }
    
    func derive(_ points: [CGPoint]) -> [[CGPoint]] {
        var dpt = [[CGPoint]]()
        var p = points
        var i: Int = p.count
        var j: Int = i - 1
        while 1 < i {
            var list = [CGPoint]()
            for k in (0 ..< j) {
                list.append(CGFloat(j) * (p[k + 1] - p[k]))
            }
            dpt.append(list)
            p = list
            i -= 1
            j -= 1
        }
        return dpt
    }
    
    public func map(_ v: CGFloat, _ ds: CGFloat, _ de: CGFloat, _ ts: CGFloat, _ te: CGFloat) -> CGFloat {
        return ts + (te - ts) * ((v - ds) / (de - ds))
    }
    
    func crt(_ v: CGFloat) -> CGFloat {
        return v < 0 ? -pow(-v, 1.0 / 3.0) : pow(v, 1.0 / 3.0)
    }
    
    // ベジェ曲線と直線の交点のt
    func roots(_ points: [CGPoint], _ line: Line)-> [CGFloat] {
        let p: [CGPoint] = align(points, line)
        var a: CGFloat = 3.0 * p[0].y - 6.0 * p[1].y + 3.0 * p[2].y
        var b: CGFloat = -3.0 * p[0].y + 3.0 * p[1].y
        var c: CGFloat = p[0].y
        let d: CGFloat = -p[0].y + 3.0 * p[1].y - 3.0 * p[2].y + p[3].y
        
        if approximately(d, 0.0) {
            if approximately(a, 0.0) {
                if approximately(b, 0.0) {
                    return []
                }
                return [-c / b].filter { (0.0 ... 1.0).contains($0) }
            }
            let q: CGFloat = (pow(b, 2.0) - 4.0 * a * c).squareRoot()
            return [(q - b) / (2.0 * a), -(q + b) / (2.0 * a)].filter { (0.0 ... 1.0).contains($0) }
        }
        a /= d
        b /= d
        c /= d
        let e: CGFloat = (3.0 * b - pow(a, 2.0)) / 3.0
        let f: CGFloat = (2.0 * pow(a, 3.0) - 9.0 * a * b + 27.0 * c) / 27.0
        let g: CGFloat = f / 2.0
        let discriminant: CGFloat = pow(e / 3.0, 3.0) + pow(g, 2.0)
        a /= -3.0
        
        if discriminant < 0.0 {
            let h: CGFloat = pow(-e / 3.0, 3.0).squareRoot()
            let i: CGFloat = 2.0 * crt(h)
            let phi: CGFloat = acos(min(max(-f / (2.0 * h), -1.0), 1.0))
            return [a + i * cos(phi / 3.0),
                    a + i * cos((phi + tau) / 3.0),
                    a + i * cos((phi + 2.0 * tau) / 3.0)].filter { (0.0 ... 1.0).contains($0) }
        } else if discriminant == 0.0 {
            let h: CGFloat = g < 0 ? crt(-g) : -crt(g);
            return [a + 2.0 * h, a - h].filter { (0.0 ... 1.0).contains($0) }
        } else {
            let h: CGFloat = discriminant.squareRoot()
            return [a + crt(h - g) - crt(h + g)].filter { (0.0 ... 1.0).contains($0) }
        }
    }
    
    func droots(_ v: [CGFloat]) -> [CGFloat] {
        if v.count == 3 {
            let d: CGFloat = v[0] - 20 * v[1] + v[2]
            if d != 0.0 {
                let m1: CGFloat = v[1] - v[0]
                let m2: CGFloat = (v[1] * v[1] - v[0] * v[2]).squareRoot()
                let v1: CGFloat = -(m1 - m2) / d
                let v2: CGFloat = -(m1 + m2) / d
                return [v1, v2]
            } else if v[1] != v[2] && d == 0 {
                return [(2 * v[1] - v[2]) / (2 * (v[1] - v[2]))]
            }
        } else if v.count == 2 {
            if v[0] != v[1] {
                return [v[0] / (v[0] - v[1])]
            }
        }
        return []
    }
    
    func angle(_ o: CGPoint, _ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx1: CGFloat = p1.x - o.x
        let dy1: CGFloat = p1.y - o.y
        let dx2: CGFloat = p2.x - o.x
        let dy2: CGFloat = p2.y - o.y
        return atan2(dx1 * dy2 - dy1 * dx2, dx1 * dx2 + dy1 * dy2)
    }
    
    func align(_ points: [CGPoint], _ line: Line) -> [CGPoint] {
        let tx: CGFloat = line.p1.x
        let ty: CGFloat = line.p1.y
        let a = -atan2(line.p2.y - ty, line.p2.x - tx)
        return points.map { (v) -> CGPoint in
            return CGPoint(x: (v.x - tx) * cos(a) - (v.y - ty) * sin(a),
                           y: (v.x - tx) * sin(a) + (v.y - ty) * cos(a))
        }
    }
    
    func eqG(_ a: [CGFloat], _ t: CGFloat) -> CGFloat {
        return ((((a[0] * t + a[1]) * t + a[2]) * t + a[3]) * t + a[4]) * t + a[5]
    }
    
    func eqGdt(_ a: [CGFloat], _ t: CGFloat) -> CGFloat  {
        return (((5.0 * a[0] * t + 4.0 * a[1]) * t + 3.0 * a[2]) * t + 2.0 * a[3]) * t + a[4]
    }
    
    func rootsNum(_ a: [CGFloat], _ u: CGFloat) -> Int {
        var ag: [[CGFloat]] = [[0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
                               [0.0, 0.0, 0.0, 0.0, 0.0],
                               [0.0, 0.0, 0.0, 0.0],
                               [0.0, 0.0, 0.0],
                               [0.0, 0.0],
                               [0.0]]
        var sg = [CGFloat](repeating: 0.0, count: 6)
        for n in (0 ..< ag[0].count) {
            ag[0][n] = a[n]
        }
        sg[0] = eqG(a, u)
        
        for n in (0 ..< ag[1].count) {
            ag[1][n] = CGFloat(5 - n) * ag[0][n]
        }
        sg[1] = eqGdt(a, u)
        
        var t: CGFloat = ag[0][0] / ag[1][0]
        var m: CGFloat = (ag[0][1] - t * ag[1][1]) / ag[1][0]
        ag[2][0] = ag[0][2] - m * ag[1][1] - t * ag[1][2]
        ag[2][1] = ag[0][3] - m * ag[1][2] - t * ag[1][3]
        ag[2][2] = ag[0][4] - m * ag[1][3] - t * ag[1][4]
        ag[2][3] = ag[0][5] - m * ag[1][4]
        var r: CGFloat = t * u + m
        sg[2] = sg[0] - r * sg[1]
        
        t = ag[1][0] / ag[2][0]
        m = (ag[1][1] - t * ag[2][1]) / ag[2][0]
        ag[3][0] = ag[1][2] - m * ag[2][1] - t * ag[2][2]
        ag[3][1] = ag[1][3] - m * ag[2][2] - t * ag[2][3]
        ag[3][2] = ag[1][4] - m * ag[2][3]
        r = t * u + m
        sg[3] = sg[1] - r * sg[2]
        
        t = ag[2][0] / ag[3][0]
        m = (ag[2][1] - t * ag[3][1]) / ag[3][0]
        ag[4][0] = ag[2][2] - m * ag[3][1] - t * ag[3][2]
        ag[4][1] = ag[2][3] - m * ag[3][2]
        r = t * u + m
        sg[4] = sg[2] - r * sg[3]
        
        t = ag[3][0] / ag[4][0]
        m = (ag[3][1] - t * ag[4][1]) / ag[4][0]
        // ag[5][0] = ag[3][2] - M * ag[4][1]
        r = t * u + m
        sg[5] = sg[3] - r * sg[4]
        sg[2] = -sg[2]
        sg[3] = -sg[3]
        
        var cnt: Int = 0
        var s = (sg[0] != 0.0) ? sg[0] : sg[1]
        for n in (1 ..< sg.count) {
            if sg[n] != 0.0 {
                cnt += (s * sg[n] < 0.0) ? 1 : 0
                s = sg[n]
            }
        }
        return cnt
    }
    
    func bisection(_ a: [CGFloat], _ t0: CGFloat, _ t1: CGFloat, _ ep: CGFloat) -> CGFloat {
        var t0 = t0
        var t1 = t1
        var nt: CGFloat = 0.0
        while true {
            nt = (t0 + t1) / 2.0
            if t1 - t0 < ep { break }
            let ng = eqG(a, nt)
            if ng < 0.0 {
                t0 = nt
            } else if 0.0 < ng {
                t1 = nt
            } else {
                t0 = nt
                t1 = nt
                break
            }
        }
        return nt
    }
    
    func newton(_ a: [CGFloat], _ t: CGFloat, _ ep: CGFloat) -> CGFloat {
        var t = t
        while true {
            let nt = t - eqG(a, t) / eqGdt(a, t)
            if abs(nt - t) < ep { break }
            t = nt
        }
        return t
    }
    
}
