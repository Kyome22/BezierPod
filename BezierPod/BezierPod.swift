//
//  BezierPod.swift
//  BezierPod
//
//  Created by Takuto Nakamura on 2019/05/22.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import CoreGraphics

fileprivate let epsilon: CGFloat = 0.5 // important for error
typealias DivideList = (list: [[Bezier]], loop: [Bezier], remainder: [Bezier])

class BezierPod {
    
    static func isError(_ p1: CGPoint, _ p2: CGPoint) -> Bool {
        return p1.length(from: p2) < epsilon
    }
    
    static func isContains(_ points: [CGPoint], _ point: CGPoint) -> CGPoint? {
        return points.first { (p) -> Bool in
            return point.length(from: p) < epsilon
        }
    }
    
    static func append( _ point: CGPoint, to points: inout [CGPoint]) {
        for n in (0 ..< points.count) {
            if point.length(from: points[n]) < 2.0 * epsilon {
                points[n] = (points[n] + point) / 2.0
                return
            }
        }
        points.append(point)
    }
    
    static func exclude(_ list: inout [[Bezier]], _ originals: [Bezier], _ distance: CGFloat) {
        for n in (0 ..< list.count).reversed() {
            if BezierPod.isClose(list[n]) {
                let center: CGPoint = BezierPod.calcCenter(list[n])
                for original in originals {
                    if original.distance(from: center).value < distance {
                        list.remove(at: n)
                        break
                    }
                }
            }
        }
    }
    
    static func isClose(_ beziers: [Bezier]) -> Bool {
        if beziers.isEmpty { return false }
        return isError(beziers.first!.p1, beziers.last!.p2)
    }
    
    static func cleaning(_ beziers: inout [Bezier]) {
        for n in (0 ..< beziers.count).reversed() {
            if BezierPod.isError(beziers[n].p1, beziers[n].p2) {
                beziers.remove(at: n)
            }
        }
        for n in (1 ..< beziers.count) {
            if BezierPod.isError(beziers[n].p1, beziers[n - 1].p2) {
                let average = (beziers[n].p1 + beziers[n - 1].p2) / 2.0
                beziers[n].points[0] = average
                beziers[n - 1].points[3] = average
            }
        }
    }
    
    static func squeezing(_ beziers: inout [Bezier], _ points: [CGPoint]) -> [CGPoint] {
        let squeezed: [CGPoint] = points.compactMap { (p) -> CGPoint? in
            // calculating average is too important
            var cnt: Int = 0
            for n in (1 ..< beziers.count) {
                if BezierPod.isError(p, beziers[n].p1) {
                    cnt += 1
                    beziers[n].points[0] = p
                    beziers[n - 1].points[3] = p
                }
            }
            return (2 <= cnt) ? p : nil
        }
        return squeezed
    }
    
    static func dividing(_ beziers: [Bezier], _ intersections: [CGPoint]) -> [[Bezier]] {
        if beziers.count < 2 { return [beziers] }
        var list: [[Bezier]] = [[beziers[0]]]
        var loop = [Bezier]()
        var remainder = [Bezier]()
        var preIntersection: CGPoint?
        for i in (1 ..< beziers.count) {
            if preIntersection == nil {
                if let intersection = BezierPod.isContains(intersections, beziers[i].p1) {
                    preIntersection = intersection
                    loop.append(beziers[i])
                } else {
                    list[list.count - 1].append(beziers[i])
                }
            } else {
                loop.append(beziers[i])
                if BezierPod.isError(preIntersection!, beziers[i].p2) {
                    remainder.append(contentsOf: beziers[i + 1 ..< beziers.count])
                    break
                }
            }
        }
        if !remainder.isEmpty {
            var divided = BezierPod.dividing(remainder, intersections)
            list[list.count - 1].append(contentsOf: divided.removeFirst())
            list.append(contentsOf: divided)
        }
        if !loop.isEmpty {
            list.append(contentsOf: BezierPod.dividing(loop, intersections))
        }
        return list
    }
    
    static func grouping(_ beziers: [Bezier]) -> [[Bezier]] {
          if beziers.count < 2 { return [beziers] }
          var array = beziers
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
    
    static func calcCenter(_ beziers: [Bezier]) -> CGPoint {
        if beziers.isEmpty { return .zero }
        let sum = beziers.reduce(CGPoint.zero) { (res, bezier) -> CGPoint in
            return res + bezier.center
        }
        return sum / CGFloat(beziers.count)
    }
    
    static func offsetProcess(_ a1: CGPoint, _ a2: CGPoint, _ b1: CGPoint, _ b2: CGPoint, _ d: CGFloat, _ corner: Corner) -> [Bezier] {
        var beziers = [Bezier]()
        let ea: CGFloat = (a2 - a1).exteriorAngle(b2 - b1)
        if ea * d > 0.0 {
            let d: CGFloat = abs(d) * tan(min(CGFloat.pi / 4.0, abs(ea) / 2.0))
            let before = Line(p: a2, v: a1, length: -d)
            beziers.append(before)
            let after = Line(p: b1, v: b2, length: -d).reversed
            if !BezierPod.isError(after.p1, before.p2) {
                beziers.append(Line(p1: before.p2, p2: after.p1))
            }
            beziers.append(after)
        } else {
            beziers.append(Line(p1: a2, p2: b1))
        }
        return beziers
        
        // switch corner {
        // case .miter:
        //     var d: CGFloat = distance * tan(op.theta / 2.0)
        //     if abs(op.theta / 2.0) < (CGFloat.pi / 36.0) {
        //         d = distance * tan(CGFloat.pi / 4.0)
        //     }
        //     let before = Line(p: last.p2, v: last.c2, length: -d)
        //     beziers.append(before)
        //     let after = line.extend(d, 0.0)
        //     beziers.append(after)
        // case .bevel:
        //     let d: CGFloat = distance * tan(min(CGFloat.pi / 4.0, op.theta / 2.0))
        //     let before = Line(p: last.p2, v: last.c2, length: -d)
        //     beziers.append(before)
        //     let after = line.extend(d, 0.0)
        //     if 0.5 < after.p1.length(from: before.p2) {
        //         beziers.append(Line(p1: beziers.last!.p2, p2: after.p1))
        //     }
        //     beziers.append(after)
        // case .round:
        //
        // }
    }
    
    static func lineOffsetProcess(_ beziers: inout [Bezier], _ line: Line, _ distance: CGFloat, _ corner: Corner) {
        if beziers.isEmpty { return }
        var segments = [Bezier]()
        if let last = beziers.last as? Line {
            segments = BezierPod.offsetProcess(last.p1, last.p2, line.p1, line.p2, distance, corner)
        } else if let last = beziers.last as? Curve {
            segments = BezierPod.offsetProcess(last.c2, last.p2, line.p1, line.p2, distance, corner)
        }
        beziers.append(contentsOf: segments)
    }
    
    static func curveOffsetProcess(_ beziers: inout [Bezier], _ curve: Curve, _ distance: CGFloat, _ corner: Corner) {
        if beziers.isEmpty { return }
        var segments = [Bezier]()
        if let last = beziers.last as? Line {
            segments = BezierPod.offsetProcess(last.p1, last.p2, curve.p1, curve.c1, distance, corner)
        } else if let last = beziers.last as? Curve {
            segments = BezierPod.offsetProcess(last.c2, last.p2, curve.p1, curve.c1, distance, corner)
        }
        beziers.append(contentsOf: segments)
    }
    
    static func resolveIntersection(_ beziers: inout [Bezier]) -> [CGPoint] {
        if beziers.isEmpty { return [] }
        var joints = [CGPoint]()
        for i in (0 ..< beziers.count - 1) {
            // collecting joints between two curves
            if BezierPod.isError(beziers[i].p2, beziers[i + 1].p1) {
                let average = (beziers[i].p2 + beziers[i + 1].p1) / 2.0
                BezierPod.append(average, to: &joints)
            }
            // collecting self intersections
            if let intersects = beziers[i].selfIntersects() {
                intersects.forEach { (intersect) in
                    BezierPod.append(beziers[i].compute(intersect.tSelf), to: &joints)
                }
            }
            // collecting other intersections
            for j in ((i + 1) ..< beziers.count) {
                if let intersects = beziers[i].intersects(with: beziers[j]) {
                    intersects.forEach { (intersect) in
                        BezierPod.append(beziers[i].compute(intersect.tSelf), to: &joints)
                    }
                }
            }
        }
        beziers.append(beziers.first!)
        // spliting original curves via joints
        var i: Int = 0
        while i < beziers.count {
            for joint in joints {
                let d = beziers[i].distance(from: joint)
                if 2.0 * epsilon < d.value { continue }
                if beziers[i].between(d.t, 0.0, 1.0) {
                    if let line = beziers[i] as? Line {
                         let splitedLine: LinePair = line.split(d.t)
                        splitedLine.left.points[3] = joint
                        splitedLine.right.points[0] = joint
                        line.updateSelf(splitedLine.left)
                        beziers.insert(splitedLine.right, at: i + 1)
                    } else if let curve = beziers[i] as? Curve {
                        let splitedCurve: CurvePair = curve.split(d.t)
                        splitedCurve.left.points[3] = joint
                        splitedCurve.right.points[0] = joint
                        curve.updateSelf(splitedCurve.left)
                        beziers.insert(splitedCurve.right, at: i + 1)
                    }
                }
            }
            i += 1
        }
        beziers.removeLast()
        BezierPod.cleaning(&beziers)
        return BezierPod.squeezing(&beziers, joints)
    }
    
    static func removeExtraPath(_ beziers: [Bezier], _ originals: [Bezier], _ intersections: [CGPoint], _ distance: CGFloat) -> [[Bezier]] {
        var list: [[Bezier]] = BezierPod.dividing(beziers, intersections)
        BezierPod.exclude(&list, originals, abs(distance))
        let flatList: [Bezier] = list.flatMap { (bs) -> [Bezier] in return bs }
        return BezierPod.grouping(flatList)
    }
        
}

