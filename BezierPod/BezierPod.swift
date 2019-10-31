//
//  BezierPod.swift
//  BezierPod
//
//  Created by Takuto Nakamura on 2019/05/22.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import Foundation

fileprivate let epsilon: CGFloat = 0.5

class BezierPod {
    
    static func isError(_ p1: NSPoint, _ p2: NSPoint) -> Bool {
        return p1.length(from: p2) < epsilon
    }
    
    static func isContains(_ points: [NSPoint], _ point: NSPoint) -> Bool {
        return points.contains { (p) -> Bool in
            return point.length(from: p) < epsilon
        }
    }
    
    static func append( _ point: NSPoint, to points: inout [NSPoint]) {
        if !points.contains(where: { (p) -> Bool in
            return point.length(from: p) < epsilon
        }) {
            points.append(point)
        }
    }
    
    static func isClose(_ beziers: [Bezier]) -> Bool {
        if beziers.isEmpty { return false }
        return BezierPod.isError(beziers.first!.p1, beziers.last!.p2)
    }
    
    static func cleaning(_ array: inout [Bezier]) {
        for n in (0 ..< array.count).reversed() {
            if BezierPod.isError(array[n].p1, array[n].p2) {
                array.remove(at: n)
            }
        }
    }
    
    static func classify(_ array: inout [Bezier]) -> [[Bezier]] {
        if array.count == 1 {
            return [array]
        }
        var results = [[Bezier]]()
        var i: Int = 0
        var j: Int = 0
        while i < array.count - 1 {
            if results.isEmpty || results.last!.last! !== array[i] {
                results.append([array[i]])
            }
            j = i + 1
            while j < array.count {
                if BezierPod.isError(array[i].p2, array[j].p1) {
                    let bezier = array[j]
                    array.remove(at: j)
                    array.insert(bezier, at: i + 1)
                    results[results.count - 1].append(bezier)
                    break
                }
                j += 1
            }
            i += 1
        }
        return results
    }
    
    static func classify2(_ beziers: [Bezier]) -> [[Bezier]] {
        if beziers.count < 2 { return [beziers] }
        var array = beziers
        BezierPod.cleaning(&array)
        // sort array
        for i in (0 ..< array.count - 1) {
            for j in ((i + 1 ..< array.count)) {
                if BezierPod.isError(array[i].p2, array[j].p1) {
                    let bezier = array.remove(at: j)
                    array.insert(bezier, at: i + 1)
                    break
                }
            }
        }
        var results: [[Bezier]] = [[array[0]]]
        for i in (1 ..< array.count) {
            if !BezierPod.isError(array[i].p1, array[i - 1].p2) {
                results.append([])
            }
            results[results.count - 1].append(array[i])
        }
        return results
    }
    
    static func calcCenter(_ beziers: [Bezier]) -> NSPoint {
        if beziers.isEmpty { return .zero }
        let sum = beziers.reduce(NSPoint.zero) { (res, bezier) -> NSPoint in
            return res + bezier.center
        }
        return sum / CGFloat(beziers.count)
    }
    
    static func offsetProcess(_ a1: NSPoint, _ a2: NSPoint, _ b1: NSPoint, _ b2: NSPoint, _ d: CGFloat, _ corner: Corner) -> [Bezier] {
        var beziers = [Bezier]()
        let ea: CGFloat = (a2 - a1).exteriorAngle(b2 - b1)
        if ea * d > 0.0 {
            let d: CGFloat = abs(d) * tan(min(CGFloat.pi / 4.0, abs(ea) / 2.0))
            let before = Line(p: a2, v: a1, length: -d)
            beziers.append(before)
            let after = Line(p: b1, v: b2, length: -d).reversed
            if epsilon <= after.p1.length(from: before.p2) {
                beziers.append(Line(p1: before.p2, p2: after.p1))
            }
            beziers.append(after)
        } else {
            beziers.append(Line(p1: a2, p2: b1))
        }
        return beziers
        
        //                    switch corner {
                    //                    case .miter:
                    //                        var d: CGFloat = distance * tan(op.theta / 2.0)
                    //                        if abs(op.theta / 2.0) < (CGFloat.pi / 36.0) {
                    //                            d = distance * tan(CGFloat.pi / 4.0)
                    //                        }
                    //                        let before = Line(p: last.p2, v: last.c2, length: -d)
                    //                        beziers.append(before)
                    //                        let after = line.extend(d, 0.0)
                    //                        beziers.append(after)
                    //                    case .bevel:
                    //                        let d: CGFloat = distance * tan(min(CGFloat.pi / 4.0, op.theta / 2.0))
                    //                        let before = Line(p: last.p2, v: last.c2, length: -d)
                    //                        beziers.append(before)
                    //                        let after = line.extend(d, 0.0)
                    //                        if 0.5 < after.p1.length(from: before.p2) {
                    //                            beziers.append(Line(p1: beziers.last!.p2, p2: after.p1))
                    //                        }
                    //                        beziers.append(after)
                    //                    case .round:
                    //
                    //                    }
    }
    
    static func lineOffsetProcess(_ beziers: inout [Bezier], _ line: Line, _ distance: CGFloat, _ corner: Corner) {
        if beziers.isEmpty { return }
        if let last = beziers.last as? Curve {
            let segments: [Bezier] = BezierPod.offsetProcess(last.c2, last.p2, line.p1, line.p2, distance, corner)
            beziers.append(contentsOf: segments)
        } else if let last = beziers.last as? Line {
            let segments: [Bezier] = BezierPod.offsetProcess(last.p1, last.p2, line.p1, line.p2, distance, corner)
            beziers.append(contentsOf: segments)
        }
    }
    
    static func curveOffsetProcess(_ beziers: inout [Bezier], _ curve: Curve, _ distance: CGFloat, _ corner: Corner) {
        if beziers.isEmpty { return }
        if let last = beziers.last as? Curve {
            let segments: [Bezier] = BezierPod.offsetProcess(last.c2, last.p2, curve.p1, curve.c1, distance, corner)
            beziers.append(contentsOf: segments)
        } else if let last = beziers.last as? Line {
            let segments: [Bezier] = BezierPod.offsetProcess(last.p1, last.p2, curve.p1, curve.c1, distance, corner)
            beziers.append(contentsOf: segments)
        }
    }
    
    static func resolveIntersection(_ beziers: inout [Bezier]) -> [NSPoint] {
        BezierPod.cleaning(&beziers)
        if beziers.count < 2 { return [] }
        var joints = [NSPoint]()
        // collecting intersections of original curves
        for i in (0 ..< beziers.count - 2) {
            for j in ((i + 2) ..< beziers.count) {
                switch (beziers[i], beziers[j]) {
                case let (line1 as Line, line2 as Line):
                    if let intersect: Intersect = line1.intersect(line2) {
                        let intersection: NSPoint = line1.compute(intersect.tSelf)
                        BezierPod.append(intersection, to: &joints)
                    }
                case let (line as Line, curve as Curve):
                    if let intersects: [Intersect] = line.intersects(curve) {
                        let intersection: NSPoint = line.compute(intersects[0].tSelf)
                        BezierPod.append(intersection, to: &joints)
                    }
                case let (curve as Curve, line as Line):
                    if let intersects: [Intersect] = curve.intersects(line) {
                        let intersection: NSPoint = curve.compute(intersects[0].tSelf)
                        BezierPod.append(intersection, to: &joints)
                    }
                case let (curve1 as Curve, curve2 as Curve):
                    if curve1.overlaps(curve2),
                        let intersects: [Intersect] = curve1.intersects(curve2) {
                        let intersection: NSPoint = curve1.compute(intersects[0].tSelf)
                        BezierPod.append(intersection, to: &joints)
                    }
                default:
                    break
                }
            }
        }
        // collecting joints of original curves
        beziers.append(beziers.first!)
        for n in (0 ..< beziers.count - 1) {
            if BezierPod.isError(beziers[n].p2, beziers[n + 1].p1) {
                joints.append(beziers[n].p2)
            }
        }
        
        // spliting original curves via joints
        var intersections = [NSPoint]()
        var i: Int = 0
        while i < beziers.count {
            for joint in joints {
                let d = beziers[i].distance(from: joint)
                if beziers[i].between(d.t, 0.0, 1.0) && d.value < epsilon {
                    if let line = beziers[i] as? Line {
                        let splitedLine: LinePair = line.split(d.t)
                        if epsilon < splitedLine.left.lineLength && epsilon < splitedLine.right.lineLength {
                            line.updateSelf(splitedLine.left)
                            beziers.insert(splitedLine.right, at: i + 1)
                            BezierPod.append(joint, to: &intersections)
                        }
                    } else if let curve = beziers[i] as? Curve {
                        let splitedCurve: CurvePair = curve.split(d.t)
                        if epsilon < splitedCurve.left.curveLength && epsilon < splitedCurve.right.curveLength {
                            curve.updateSelf(splitedCurve.left)
                            beziers.insert(splitedCurve.right, at: i + 1)
                            BezierPod.append(joint, to: &intersections)
                        }
                    }
                }
            }
            i += 1
        }
        beziers.removeLast()
        BezierPod.cleaning(&beziers)
        return intersections
    }
    
    static func removeExtraPath(_ beziers: inout [Bezier], _ originals: [Bezier], _ intersections: [NSPoint], _ distance: CGFloat) -> [[Bezier]] {
        func removeFromList(_ list: inout [[Bezier]]) {
            for n in (0 ..< list.count).reversed() {
                if !BezierPod.isClose(list[n]) { continue }
                let center: NSPoint = BezierPod.calcCenter(list[n])
                for original in originals {
                    if original.distance(from: center).value < abs(distance) {
                        list.remove(at: n)
                        break
                    }
                }
            }
        }
        
        if 0.0 < distance {
            var list: [[Bezier]] = [[]]
            for n in (0 ..< beziers.count) {
                if BezierPod.isContains(intersections, beziers[n].p1) {
                    list.append([])
                }
                list[list.count - 1].append(beziers[n])
            }
            removeFromList(&list)
            beziers = list.flatMap { (bs) -> [Bezier] in return bs }
            return BezierPod.classify2(beziers)
        } else {
            var groups: [[Bezier]] = [[], []]
            var flag: Int = 0
            for n in (0 ..< beziers.count) {
                if BezierPod.isContains(intersections, beziers[n].p1) {
                    flag = (flag + 1) % 2
                }
                groups[flag].append(beziers[n])
            }
            var list = [[Bezier]]()
            for group in groups {
                if group.isEmpty { continue }
                list.append(contentsOf: BezierPod.classify2(group))
            }
            removeFromList(&list)
            return list
        }
    }
    
    static func cutExtraPath() {
        
    }
    
    static func chainPath() {
        
    }
        
    //    static func unite(_ curves: [Curve]) -> NSBezierPath {
    //        let path = NSBezierPath()
    //        curves.forEach { (curve) in
    //            path.move(to: curve.points[0])
    //            path.curve(to: curve.points[3],
    //                       controlPoint1: curve.points[1],
    //                       controlPoint2: curve.points[2])
    //        }
    //        return path
    //    }
    
}

