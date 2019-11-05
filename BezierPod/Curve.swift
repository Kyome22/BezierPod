//
//  Curve.swift
//  BezierPod
//
//  Created by Takuto Nakamura on 2019/10/03.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import Cocoa

typealias Extrema = (x: [CGFloat], y: [CGFloat], values: [CGFloat])
typealias CurvePair = (left: Curve, right: Curve)

public class Curve: Bezier {
    
    public private(set) var t1: CGFloat
    public private(set) var t2: CGFloat
    
    public init(points: [NSPoint], t1: CGFloat = 0.0, t2: CGFloat = 1.0) {
        self.t1 = t1
        self.t2 = t2
        super.init(points: points)
    }
    
    public func updateSelf(_ curve: Curve) {
        self.points = curve.points
        self.t1 = curve.t1
        self.t2 = curve.t2
    }
    
    public var path: NSBezierPath {
        let path = NSBezierPath()
        path.move(to: p1)
        path.curve(to: p2, controlPoint1: c1, controlPoint2: c2)
        return path
    }
    
    override public var description: String {
        return "from: \(p1), ctrl1: \(c1), ctrl2: \(c2), to: \(p2), t1: \(t1), t2: \(t2)"
    }
    
    override var center: NSPoint {
        return (p1 + c1 + c2 + p2) / 4.0
    }
    
    // ★★★ Unique Method ★★★
    override public func compute(_ t: CGFloat) -> NSPoint {
        var point = pow(1.0 - t, 3.0) * p1
        point += (3.0 * pow(1.0 - t, 2.0) * t) * c1
        point += (3.0 * (1.0 - t) * pow(t, 2.0)) * c2
        point += pow(t, 3.0) * p2
        return point
    }
    
    private func derivative(_ t: CGFloat) -> NSPoint {
        let p: [NSPoint] = derive(points)[0]
        let mt: CGFloat = 1.0 - t
        return pow(mt, 2.0) * p[0] + (2.0 * mt * t) * p[1] + pow(t, 2.0) * p[2]
    }
    
    var curveLength: CGFloat {
        let z: CGFloat = 0.5
        var t: CGFloat = 0.0
        var sum: CGFloat = 0.0
        for i in (0 ..< valuesT.count) {
            t = z * valuesT[i] + z
            let d: NSPoint = derivative(t)
            sum += valuesC[i] * d.scalar
        }
        return z * sum
    }
    
    private func normal(_ t: CGFloat) -> NSPoint {
        let d: NSPoint = derivative(t)
        let q: CGFloat = d.scalar
        return NSPoint(x: d.y / q, y: -d.x / q)
    }
    
    private func hull(_ t: CGFloat) -> [NSPoint] {
        // t: 0 <= t <= 1
        var p = points
        var q: [NSPoint] = p
        var pt = NSPoint.zero
        while p.count > 1 {
            var pts = [NSPoint]()
            for i in (0 ..< p.count - 1) {
                pt = p[i] + t * (p[i + 1] - p[i])
                q.append(pt)
                pts.append(pt)
            }
            p = pts
        }
        return q
    }
    
    func split(_ t: CGFloat) -> CurvePair {
        let q: [NSPoint] = hull(t)
        let left = Curve(points: [q[0], q[4], q[7], q[9]],
                         t1: map(0.0, 0.0, 1.0, t1, t2),
                         t2: map(t, 0.0, 1.0, t1, t2))
        let right = Curve(points: [q[9], q[8], q[6], q[3]],
                          t1: map(t, 0.0, 1.0, t1, t2),
                          t2: map(1.0, 0.0, 1.0, t1, t2))
        return (left, right)
    }
    
    func split(_ t1: CGFloat, _ t2: CGFloat) -> Curve {
        if t1 <= 0.0 {
            return split(t2).left
        }
        if 1.0 <= t2 {
            return split(t1).right
        }
        return split(t1).right.split(map(t2, t1, 1.0, 0.0, 1.0)).left
    }
    
    private var extrema: Extrema {
        let dpts: [[NSPoint]] = derive(points)
        var xElms: [CGFloat] = dpts[0].map({ (p) -> CGFloat in p.x })
        var yElms: [CGFloat] = dpts[0].map({ (p) -> CGFloat in p.y })
        var xRoots: [CGFloat] = droots(xElms)
        var yRoots: [CGFloat] = droots(yElms)
        xElms = dpts[1].map({ (p) -> CGFloat in p.x })
        yElms = dpts[1].map({ (p) -> CGFloat in p.y })
        xRoots.append(contentsOf: droots(xElms))
        yRoots.append(contentsOf: droots(yElms))
        xRoots = xRoots.filter({ (v) -> Bool in (0 ... 1).contains(v) }).sorted()
        yRoots = yRoots.filter({ (v) -> Bool in (0 ... 1).contains(v) }).sorted()
        let roots: [CGFloat] = (xRoots + yRoots).reduce([CGFloat](), { (res, v) -> [CGFloat] in
            return res.contains(v) ? res : res + [v]
        }).sorted()
        return Extrema(xRoots, yRoots, roots)
    }
    
    private var isSimple: Bool {
        let a1: CGFloat = angle(p1, p2, c1)
        let a2: CGFloat = angle(p1, p2, c2)
        if (a2 < 0.0 && 0.0 < a1) || (a1 < 0.0 && 0.0 < a2) {
            return false
        }
        let n1: NSPoint = normal(0.0)
        let n2: NSPoint = normal(1.0)
        return abs(acos(n1.x * n2.x + n1.y * n2.y)) < CGFloat.pi / 3.0
    }
    
    private var reduce: [Curve] {
        var segment: Curve!
        var values: [CGFloat] = extrema.values
        if !values.contains(0.0) {
            values.insert(0.0, at: 0)
        }
        if !values.contains(1.0) {
            values.append(1.0)
        }
        var firstPass = [Curve]()
        var t1: CGFloat = values[0]
        var t2: CGFloat = 0.0
        for i in (1 ..< values.count) {
            t2 = values[i]
            segment = split(t1, t2)
            segment.t1 = t1
            segment.t2 = t2
            firstPass.append(segment)
            t1 = t2
        }
        var secondPass = [Curve]()
        // substantive intersection threshold
        let step: CGFloat = 0.01
        firstPass.forEach { (pass) in
            t1 = 0.0
            t2 = 0.0
            while t2 <= 1.0 {
                t2 = t1 + step
                while t2 <= (1.0 + step) {
                    segment = pass.split(t1, t2)
                    if !segment.isSimple {
                        t2 -= step
                        if abs(t1 - t2) < step {
                            return
                        }
                        segment = pass.split(t1, t2)
                        segment.t1 = map(t1, 0.0, 1.0, pass.t1, pass.t2)
                        segment.t2 = map(t2, 0.0, 1.0, pass.t1, pass.t2)
                        secondPass.append(segment)
                        t1 = t2
                        break
                    }
                    t2 += step
                }
            }
            if t1 < 1.0 {
                segment = pass.split(t1, 1.0)
                segment.t1 = map(t1, 0.0, 1.0, pass.t1, pass.t2)
                segment.t2 = pass.t2
                secondPass.append(segment)
            }
        }
        return secondPass
    }
    
    private var isLinear: Bool {
        for a in align(points, Line(p1: points.first!, p2: points.last!)) {
            if abs(a.y) > 0.0001 {
                return false
            }
        }
        return true
    }
    
    func offset(_ d: CGFloat) -> [Curve] {
        if isLinear {
            let nv: NSPoint = normal(0.0)
            let coords: [NSPoint] = points.map { (v) -> NSPoint in
                return v + d * nv
            }
            return [Curve(points: coords)]
        }
        
        let reduced = reduce.map { (curve) -> Curve in
            let line1: NSPoint = curve.c1 - curve.p1
            let bridge: NSPoint = curve.c2 - curve.c1
            let line2: NSPoint = curve.p2 - curve.c2
            
            let phi1: CGFloat = line1.exteriorAngle(bridge) / 2.0
            let phi2: CGFloat = line2.exteriorAngle(bridge) / 2.0

            let n1 = d * NSPoint(x: line1.y, y: -line1.x) / line1.scalar
            let n2 = d * NSPoint(x: line2.y, y: -line2.x) / line2.scalar
            
            let nc1 = NSPoint(x: n1.x * cos(phi1) - n1.y * sin(phi1),
                               y: n1.x * sin(phi1) + n1.y * cos(phi1)) / cos(phi1)
            let nc2 = NSPoint(x: n2.x * cos(phi2) - n2.y * sin(phi2),
                               y: n2.x * sin(phi2) + n2.y * cos(phi2)) / cos(phi2)
            
            return Curve(points: [curve.p1 + n1, curve.c1 + nc1, curve.c2 + nc2, curve.p2 + n2])
        }
        
        if reduced.count < 2 { return reduced }
        for n in (1 ..< reduced.count) {
            reduced[n].points[0] = reduced[n - 1].p2
        }
        return reduced
    }
    
    func getminmax(_ x: Bool, _ list: [CGFloat]) -> MinMax {
        var list = list
        if !list.contains(0.0) {
            list.insert(0.0, at: 0)
        }
        if !list.contains(1.0) {
            list.append(1.0)
        }
        var c: NSPoint = compute(0.0)
        var minV: CGFloat = x ? c.x : c.y
        var maxV: CGFloat = x ? c.x : c.y
        for i in (1 ..< list.count) {
            c = compute(list[i])
            minV = min(minV, (x ? c.x : c.y))
            maxV = max(maxV, (x ? c.x : c.y))
        }
        return MinMax(minV, maxV, (minV + maxV) / 2.0, maxV - minV)
    }
    
    var bbox: Bbox {
        let ex: Extrema = extrema
        let x = getminmax(true, ex.x)
        let y = getminmax(false, ex.y)
        return Bbox(x, y)
    }
    
    func overlaps(_ curve: Curve) -> Bool {
        let lbbox: Bbox = self.bbox
        let tbbox: Bbox = curve.bbox
        return bboxoverlap(lbbox, tbbox)
    }
    
    func overlaps(_ line: Line) -> Bool {
        let lbbox: Bbox = self.bbox
        let tl = NSPoint(x: lbbox.x.min, y: lbbox.y.max)
        let tr = NSPoint(x: lbbox.x.max, y: lbbox.y.max)
        let bl = NSPoint(x: lbbox.x.min, y: lbbox.y.min)
        let br = NSPoint(x: lbbox.x.max, y: lbbox.y.min)
        return line.overlaps(Line(p1: tl, p2: tr))
            || line.overlaps(Line(p1: tr, p2: br))
            || line.overlaps(Line(p1: br, p2: bl))
            || line.overlaps(Line(p1: bl, p2: tl))
    }
    
    func pairIteration(_ c1: Curve, _ c2: Curve, _ threshold: CGFloat) -> [Intersect] {
        let c1b = c1.bbox
        let c2b = c2.bbox
        let r: CGFloat = 100000.0 // very important value
        if (c1b.x.size + c1b.y.size < threshold) && (c2b.x.size + c2b.y.size < threshold) {
            return [Intersect(tSelf: floor(r * (c1.t1 + c1.t2) / 2.0) / r,
                              tOther: floor(r * (c2.t1 + c2.t2) / 2.0) / r)]
        }
        let cc1 = c1.split(0.5)
        let cc2 = c2.split(0.5)
        var pairs = [CurvePair]()
        pairs.append(CurvePair(cc1.left, cc2.left))
        pairs.append(CurvePair(cc1.left, cc2.right))
        pairs.append(CurvePair(cc1.right, cc2.right))
        pairs.append(CurvePair(cc1.right, cc2.left))
        pairs = pairs.filter({ (pair) -> Bool in
            return bboxoverlap(pair.left.bbox, pair.right.bbox)
        })
        var results = [Intersect]()
        if pairs.isEmpty { return results }
        pairs.forEach { (pair) in
            results.append(contentsOf: pairIteration(pair.left, pair.right, threshold))
        }
        results = results.reduce([Intersect]()) { (res, rhs) -> [Intersect] in
            let isContains = res.contains { (lhs) -> Bool in
                return approximately(lhs.tSelf, rhs.tSelf, 0.005)
                    && approximately(lhs.tOther, rhs.tOther, 0.005)
            }
            return isContains ? res : res + [rhs]
        }
        return results
    }
    
    // line intersects
    func intersects(_ line: Line) -> [Intersect]? {
        let result: [Intersect] = roots(points, line).compactMap { (v) -> Intersect? in
            if !between(v, 0.0, 1.0) { return nil }
            let p: NSPoint = compute(v)
            guard let t: CGFloat = line.backCompute(p) else { return nil }
            if !between(t, 0.0, 1.0) { return nil }
            return Intersect(tSelf: v, tOther: t)
        }
        if result.isEmpty { return nil }
        return result
    }
    
    // intersects base
    private func intersects(_ c1: [Curve], _ c2: [Curve], _ threshold: CGFloat) -> [Intersect] {
        var pairs = [CurvePair]()
        c1.forEach { (left) in
            c2.forEach { (right) in
                if left.overlaps(right) {
                    pairs.append(CurvePair(left, right))
                }
            }
        }
        var intersections = [Intersect]()
        pairs.forEach { (pair) in
            var result: [Intersect] = pairIteration(pair.left, pair.right, threshold)
            result = result.filter { (v) -> Bool in
                return between(v.tSelf, 0.0, 1.0)
            }
            intersections.append(contentsOf: result)
        }
        return intersections
    }
    
    // self intersects
    func intersects(_ threshold: CGFloat = 0.5) -> [Intersect]? {
        let reduced: [Curve] = reduce
        var results = [Intersect]()
        for i in (0 ..< reduced.count - 2) {
            let left: [Curve] = [reduced[i]]
            let right: [Curve] = Array(reduced.suffix(from: i + 2))
            results.append(contentsOf: intersects(left, right, threshold))
        }
        if results.isEmpty { return nil }
        return results
    }
    
    // curve intersects
    func intersects(_ curve: Curve, _ threshold: CGFloat = 0.5) -> [Intersect]? {
        let result: [Intersect] = intersects(self.reduce, curve.reduce, threshold)
        if result.isEmpty { return nil }
        return result
    }
    
    override func distance(from q: NSPoint) -> (value: CGFloat, t: CGFloat) {
        var ps: [NSPoint] = points
        for n in (0 ..< ps.count) {
            ps[n] -= q
        }
        var ap = [NSPoint]()
        ap.append(-ps[0] + 3.0 * (ps[1] - ps[2]) + ps[3])
        ap.append(3.0 * (ps[0] - 2.0 * ps[1] + ps[2]))
        ap.append(3.0 * (ps[1] - ps[0]))
        ap.append(ps[0])
        let a: [CGFloat] = [
            6.0 * (ap[0].x * ap[0].x + ap[0].y * ap[0].y),
            10.0 * (ap[0].x * ap[1].x + ap[0].y * ap[1].y),
            4.0 * ((2.0 * ap[0].x * ap[2].x + ap[1].x * ap[1].x) + (2.0 * ap[0].y * ap[2].y + ap[1].y * ap[1].y)),
            6.0 * ((ap[0].x * ap[3].x + ap[1].x * ap[2].x) + (ap[0].y * ap[3].y + ap[1].y * ap[2].y)),
            2.0 * ((2.0 * ap[1].x * ap[3].x + ap[2].x * ap[2].x) + (2.0 * ap[1].y * ap[3].y + ap[2].y * ap[2].y)),
            2.0 * (ap[2].x * ap[3].x + ap[2].y * ap[3].y)
        ]
      
        let d0: CGFloat = ps[0].x * ps[0].x + ps[0].y * ps[0].y
        let d3: CGFloat = ps[3].x * ps[3].x + ps[3].y * ps[3].y
        var d: CGFloat = (d0 < d3) ? d0 : d3
        var t: CGFloat = (d0 < d3) ? 0.0 : 1.0
        var left: CGFloat = 0.0
        var right: CGFloat = 1.0
        var mult: CGFloat = 1.0
        var flag: Int = 0
        
        while true {
            right = left + mult
            let mum: Int = rootsNum(a, left) - rootsNum(a, right)
            if mult < 0.001 && 1 < mum { break }
            if mum <= 1 {
                if mum == 1 {
                    if eqG(a, left) < 0.0 && 0.0 < eqG(a, right) {
                        let t_: CGFloat = newton(a, bisection(a, left, right, 0.01), 0.0001)
                        let x: CGFloat = ((ap[0].x * t_ + ap[1].x) * t_ + ap[2].x) * t_ + ap[3].x
                        let y: CGFloat = ((ap[0].y * t_ + ap[1].y) * t_ + ap[2].y) * t_ + ap[3].y
                        let tmpd: CGFloat = x * x + y * y
                        if tmpd < d {
                            d = tmpd
                            t = t_
                        }
                    }
                }
                left += mult
                while flag % 2 == 1 {
                    flag /= 2
                    mult *= 2.0
                }
                flag += 1
            } else {
                mult /= 2.0
                flag *= 2
            }
            if 1.0 <= left {
                break
            }
        }
        return (d.squareRoot(), t)
    }
    
    func distance(between line: Line) -> CGFloat {
        if overlaps(line), let _ = intersects(line) {
            return 0.0
        }
        // 0.1 is search density
        var d: CGFloat = distance(from: line.p1).value
        let limit = Int(0.1 * line.lineLength)
        if limit < 2 { return d }
        for n in (1 ... limit) {
            let t = CGFloat(n) / CGFloat(limit)
            d = min(d, distance(from: line.compute(t)).value)
        }
        return d
    }
    
    // about edge (limited edition)
    func distance(between curve: Curve) -> CGFloat {
        if overlaps(curve), let _ = intersects(curve) {
            return 0.0
        }
        return min(distance(from: curve.p1).value,
                   distance(from: curve.p2).value)
        
        // // 0.1 is search density
        // var d: CGFloat = distance(from: curve.p1).value
        // let limit = Int(0.1 * curveLength)
        // if limit < 2 { return d }
        // for n in (1 ... limit) {
        //     let t = CGFloat(n) / CGFloat(limit)
        //     d = min(d, distance(from: curve.compute(t)).value)
        // }
        // return d
    }
    
}
