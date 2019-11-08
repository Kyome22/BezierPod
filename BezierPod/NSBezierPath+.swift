//
//  NSBezierPath+.swift
//  BezierPod
//
//  Created by Takuto Nakamura on 2019/05/22.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import Cocoa

public enum Corner {
    case bevel
    case miter
    case round
}

public extension NSBezierPath {
    
    convenience init(_ paths: [NSBezierPath]) {
        self.init()
        paths.forEach { (e) in
            self.append(e)
        }
    }
    
    func copyAttribute(from: NSBezierPath) {
        self.windingRule = from.windingRule
        self.lineWidth = from.lineWidth
        self.lineCapStyle = from.lineCapStyle
        self.lineJoinStyle = from.lineJoinStyle
        // not support line dash
    }
    
    var disassembled: [NSBezierPath] {
        var paths = [NSBezierPath]()
        var points = [NSPoint](repeating: NSPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                paths.append(NSBezierPath())
                paths.last!.copyAttribute(from: self)
                paths.last!.move(to: points[0])
            case .lineTo:
                paths.last?.line(to: points[0])
            case .curveTo:
                paths.last?.curve(to: points[2],
                                  controlPoint1: points[0],
                                  controlPoint2: points[1])
            case.closePath:
                paths.last?.close()
            @unknown default:
                fatalError()
            }
        }
        for n in (0 ..< paths.count).reversed() {
            if paths[n].elementCount < 2 {
                paths.remove(at: n)
            }
        }
        return paths
    }
    
    var length: CGFloat {
        var length: CGFloat = 0.0
        var prePoint = NSPoint.zero
        var lastMoved = NSPoint.zero
        var points = [NSPoint](repeating: NSPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                prePoint = points[0]
                lastMoved = points[0]
            case .lineTo:
                length += points[0].length(from: prePoint)
                prePoint = points[0]
            case .curveTo:
                let bezier = Curve(points: [prePoint] + points)
                length += bezier.curveLength
                prePoint = points[2]
            case.closePath:
                length += lastMoved.length(from: prePoint)
            @unknown default:
                fatalError()
            }
        }
        return length
    }
    
    // ★★★ Table of points ★★★
    func getLookUpTable(density: CGFloat) -> [NSPoint] {
        var lut = [NSPoint]()
        if density <= 0.0 || 1.0 < density { return lut }
        var len: CGFloat = 0
        var cnt: Int = 0
        var fin: Int = 0
        var prePoint = NSPoint.zero
        var lastMoved = NSPoint.zero
        var points = [NSPoint](repeating: NSPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            fin = (i == self.elementCount - 1 ? 1 : 0)
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                prePoint = points[0]
                lastMoved = points[0]
            case .lineTo:
                len = points[0].length(from: prePoint)
                cnt = Int(density * len)
                for i in (0 ..< cnt + fin) {
                    lut.append(prePoint + (CGFloat(i) / CGFloat(cnt)) * (points[0] - prePoint))
                }
                prePoint = points[0]
            case .curveTo:
                let bezier = Curve(points: [prePoint] + points)
                len = bezier.curveLength
                cnt = Int(density * len)
                for t in (0 ..< cnt + fin).map({ (n) -> CGFloat in return CGFloat(n) / CGFloat(cnt) }) {
                    lut.append(bezier.compute(t))
                }
                prePoint = points[2]
            case.closePath:
                len = lastMoved.length(from: prePoint)
                cnt = Int(density * len)
                for i in (0 ..< cnt) {
                    lut.append(prePoint + (CGFloat(i) / CGFloat(cnt)) * (lastMoved - prePoint))
                }
            @unknown default:
                fatalError()
            }
        }
        return lut
    }
    
    // ★★★ Get Offset Path ★★★
    func offset(_ distance: CGFloat, _ corner: Corner = .miter) -> [NSBezierPath] {
        if distance == 0.0 { return [self] }
        if self.elementCount < 2 { return [] }
        var originals = [Bezier]()
        var beziers = [Bezier]()
        var prePoint = NSPoint.zero
        var lastMoved = NSPoint.zero
        var points = [NSPoint](repeating: NSPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                prePoint = points[0]
                lastMoved = points[0]
            case .lineTo:
                let line = Line(p1: prePoint, p2: points[0])
                originals.append(line)
                let offset: Line = line.offset(distance)
                BezierPod.lineOffsetProcess(&beziers, offset, distance, corner)
                beziers.append(offset)
                prePoint = points[0]
            case .curveTo:
                let curve = Curve(points: [prePoint] + points)
                originals.append(curve)
                let offsets: [Curve] = curve.offset(distance)
                BezierPod.curveOffsetProcess(&beziers, offsets[0], distance, corner)
                beziers.append(contentsOf: offsets)
                prePoint = points[2]
            case.closePath:
                let line = Line(p1: prePoint, p2: lastMoved)
                originals.append(line)
                let offset: Line = line.offset(distance)
                BezierPod.lineOffsetProcess(&beziers, offset, distance, corner)
                beziers.append(offset)
                if let first = beziers.first as? Curve {
                    BezierPod.curveOffsetProcess(&beziers, first, distance, corner)
                } else if let first = beziers.first as? Line {
                    BezierPod.lineOffsetProcess(&beziers, first, distance, corner)
                }
            @unknown default:
                fatalError()
            }
        }
        let intersections: [NSPoint] = BezierPod.resolveIntersection(&beziers)
        let groups: [[Bezier]] = BezierPod.removeExtraPath(&beziers, originals, intersections, distance)
//        let groups = beziers.map { (b) -> [Bezier] in
//            return [b]
//        }
        var offsetPaths = [NSBezierPath]()
        for group in groups {
            if group.isEmpty { continue }
            offsetPaths.append(NSBezierPath())
            offsetPaths.last!.copyAttribute(from: self)
            offsetPaths.last!.move(to: group.first!.p1)
            group.forEach { (bezier) in
                if let curve = bezier as? Curve {
                    offsetPaths.last!.curve(to: curve.p2,
                                            controlPoint1: curve.c1,
                                            controlPoint2: curve.c2)
                } else if let line = bezier as? Line {
                    offsetPaths.last!.line(to: line.p2)
                }
            }
            if group.last!.p2.length(from: group.first!.p1) < 0.5 {
                offsetPaths.last!.close()
            }
        }
        return offsetPaths
    }
    
    // ★★★ Get Union Path ★★★
    func or(_ path: NSBezierPath) {
        
    }
    
    // ★★★ Get Intersection Path ★★★
    func and(_ path: NSBezierPath) {
        
    }
    
    // ★★★ Get Difference Path ★★★
    func not(_ path: NSBezierPath) {
        
    }
    
    // ★★★ Get Symmetric Difference Path ★★★
    func xor(_ path: NSBezierPath) {
        
    }
    
    // 現状のこいつはあくまで開始点と終了点が1つずつの時の一番短いBezier曲線でしか動かない
    func getSplitSegment(_ t: CGFloat) -> NSBezierPath? {
        var paths = [NSBezierPath]()
        if t <= 0.0 || 1.0 <= t { return nil }
        var prePoint = NSPoint.zero
        var points = [NSPoint](repeating: NSPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                paths.append(NSBezierPath())
                paths.last?.copyAttribute(from: self)
                paths.last?.move(to: points[0])
                prePoint = points[0]
            case .lineTo:
                let pt = prePoint + t * (points[0] - prePoint)
                paths.last?.line(to: pt)
                paths.append(NSBezierPath())
                paths.last?.copyAttribute(from: self)
                paths.last?.move(to: pt)
                paths.last?.line(to: points[0])
                prePoint = points[0]
            case .curveTo:
                let pts = Curve(points: [prePoint] + points).split(t)
                let left = pts.left.points
                let right = pts.right.points
                paths.last?.curve(to: left[3], controlPoint1: left[1], controlPoint2: left[2])
                paths.append(NSBezierPath())
                paths.last?.copyAttribute(from: self)
                paths.last?.move(to: right[0])
                paths.last?.curve(to: right[3], controlPoint1: right[1], controlPoint2: right[2])
                prePoint = points[2]
            case.closePath:
                paths.last?.close()
            @unknown default:
                fatalError()
            }
        }
        return paths.isEmpty ? nil : paths.first!
    }
    
    func getSplitSegment(_ t1: CGFloat, _ t2: CGFloat) -> NSBezierPath? {
        var paths = [NSBezierPath]()
        if !(0.0 ... 1.0).contains(t1) || !(0.0 ... 1.0).contains(t2) || t1 > t2 { return nil }
        var prePoint = NSPoint.zero
        var points = [NSPoint](repeating: NSPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                prePoint = points[0]
            case .lineTo:
                let pt1 = prePoint + t1 * (points[0] - prePoint)
                let pt2 = prePoint + t2 * (points[0] - prePoint)
                paths.append(NSBezierPath())
                paths.last?.copyAttribute(from: self)
                paths.last?.move(to: pt1)
                paths.last?.line(to: pt2)
                prePoint = points[0]
            case .curveTo:
                let pts = Curve(points: [prePoint] + points).split(t1, t2).points
                paths.append(NSBezierPath())
                paths.last?.copyAttribute(from: self)
                paths.last?.move(to: pts[0])
                paths.last?.curve(to: pts[3], controlPoint1: pts[1], controlPoint2: pts[2])
                prePoint = points[2]
            case.closePath:
                paths.last?.close()
            @unknown default:
                fatalError()
            }
        }
        return paths.isEmpty ? nil : paths.first!
    }
    
    // 現状のこいつはあくまで開始点と終了点が1つずつの時の一番短いBezier曲線でしか動かない
    func getLineIntersects(_ line: Line) -> [NSPoint] {
        var intersects = [NSPoint]()
        var prePoint = NSPoint.zero
        var points = [NSPoint](repeating: NSPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                prePoint = points[0]
            case .lineTo:
                prePoint = points[0]
            case .curveTo:
                let bezier = Curve(points: [prePoint] + points)
                bezier.intersects(line)?.forEach({ (intersect) in
                    intersects.append(bezier.compute(intersect.tSelf))
                })
                prePoint = points[2]
            case.closePath:
                break
            @unknown default:
                fatalError()
            }
        }
        return intersects
    }
    
    // 現状のこいつはあくまで開始点と終了点が1つずつの時の一番短いBezier曲線でしか動かない
    func getSelfIntersects() -> [NSPoint] {
        var intersects = [NSPoint]()
        var prePoint = NSPoint.zero
        var points = [NSPoint](repeating: NSPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                prePoint = points[0]
            case .lineTo:
                prePoint = points[0]
            case .curveTo:
                let bezier = Curve(points: [prePoint] + points)
                bezier.intersects()?.forEach({ (intersect) in
                    intersects.append(bezier.compute(intersect.tSelf))
                })
                prePoint = points[2]
            case.closePath:
                break
            @unknown default:
                fatalError()
            }
        }
        return intersects
    }
    
    func getCurveIntersects(_ other: NSBezierPath) -> [NSPoint] {
        var intersects = [NSPoint]()
        var selfPrePoint = NSPoint.zero
        var selfPoints = [NSPoint](repeating: NSPoint.zero, count: 3)
        var otherPrePoint = NSPoint.zero
        var otherPoints = [NSPoint](repeating: NSPoint.zero, count: 3)
        
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &selfPoints) {
            case .moveTo:
                selfPrePoint = selfPoints[0]
            case .lineTo:
                selfPrePoint = selfPoints[0]
            case .curveTo:
                let selfBezier = Curve(points: [selfPrePoint] + selfPoints)
                for j in (0 ..< other.elementCount) {
                    switch other.element(at: j, associatedPoints: &otherPoints) {
                    case .moveTo:
                        otherPrePoint = otherPoints[0]
                    case .lineTo:
                        otherPrePoint = otherPoints[0]
                    case .curveTo:
                        let otherBezier = Curve(points: [otherPrePoint] + otherPoints)
                        selfBezier.intersects(otherBezier)?.forEach({ (intersect) in
                            intersects.append(selfBezier.compute(intersect.tSelf))
                        })
                        otherPrePoint = otherPoints[2]
                    case.closePath:
                        break
                    @unknown default:
                        fatalError()
                    }
                }
                selfPrePoint = selfPoints[2]
            case.closePath:
                break
            @unknown default:
                fatalError()
            }
        }
        return intersects
    }
        
}
