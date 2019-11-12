//
//  NSBezierPath+.swift
//  BezierPod
//
//  Created by Takuto Nakamura on 2019/05/22.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import AppKit
import CoreGraphics

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
        var points = [CGPoint](repeating: CGPoint.zero, count: 3)
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
        var prePoint = CGPoint.zero
        var lastMoved = CGPoint.zero
        var points = [CGPoint](repeating: CGPoint.zero, count: 3)
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
    func getLookUpTable(density: CGFloat) -> [CGPoint] {
        var lut = [CGPoint]()
        if density <= 0.0 || 1.0 < density { return lut }
        var len: CGFloat = 0
        var cnt: Int = 0
        var fin: Int = 0
        var prePoint = CGPoint.zero
        var lastMoved = CGPoint.zero
        var points = [CGPoint](repeating: CGPoint.zero, count: 3)
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
    // not support compound path completely...
    func offset(_ distance: CGFloat, _ corner: Corner = .miter) -> [NSBezierPath] {
        if distance == 0.0 { return [self] }
        if self.elementCount < 2 { return [] }
        var originals = [Bezier]()
        var list = [[Bezier]]()
        var prePoint = CGPoint.zero
        var lastMoved = CGPoint.zero
        var points = [CGPoint](repeating: CGPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                prePoint = points[0]
                lastMoved = points[0]
                list.append([])
            case .lineTo:
                let line = Line(p1: prePoint, p2: points[0])
                originals.append(line)
                let offset: Line = line.offset(distance)
                BezierPod.lineOffsetProcess(&list[list.count - 1], offset, distance, corner)
                list[list.count - 1].append(offset)
                prePoint = points[0]
            case .curveTo:
                let curve = Curve(points: [prePoint] + points)
                originals.append(curve)
                let offsets: [Curve] = curve.offset(distance)
                BezierPod.curveOffsetProcess(&list[list.count - 1], offsets[0], distance, corner)
                list[list.count - 1].append(contentsOf: offsets)
                prePoint = points[2]
            case.closePath:
                if list[list.count - 1].isEmpty { break }
                let line = Line(p1: prePoint, p2: lastMoved)
                originals.append(line)
                let offset: Line = line.offset(distance)
                BezierPod.lineOffsetProcess(&list[list.count - 1], offset, distance, corner)
                list[list.count - 1].append(offset)
                if let line = list[list.count - 1].first as? Line {
                    BezierPod.lineOffsetProcess(&list[list.count - 1], line, distance, corner)
                } else if let curve = list[list.count - 1].first as? Curve {
                    BezierPod.curveOffsetProcess(&list[list.count - 1], curve, distance, corner)
                }
            @unknown default:
                fatalError()
            }
        }
        var groups = [[Bezier]]()
        for n in (0 ..< list.count) {
            let intersections: [CGPoint] = BezierPod.resolveIntersection(&list[n])
            // groups.append(contentsOf: list[n].map({ (b) -> [Bezier] in
            //     return [b]
            // }))
            groups.append(contentsOf: BezierPod.removeExtraPath(list[n], originals, intersections, distance))
        }
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
            if BezierPod.isError(group.last!.p2, group.first!.p1) {
                offsetPaths.last!.close()
            }
        }
        return offsetPaths
    }
    
    // ★★★ Get Beziers of Original Path ★★★
    private func convertBeziers() -> [Bezier] {
        var beziers = [Bezier]()
        var prePoint = CGPoint.zero
        var lastMoved = CGPoint.zero
        var points = [CGPoint](repeating: CGPoint.zero, count: 3)
        for i in (0 ..< self.elementCount) {
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:
                prePoint = points[0]
                lastMoved = points[0]
            case .lineTo:
                let line = Line(p1: prePoint, p2: points[0])
                beziers.append(line)
            case .curveTo:
                let curve = Curve(points: [prePoint] + points)
                beziers.append(curve)
            case.closePath:
                if beziers.isEmpty { break }
                let line = Line(p1: prePoint, p2: lastMoved)
                beziers.append(line)
            @unknown default:
                fatalError()
            }
        }
        return beziers
    }
    
//    func divideSelf() -> [NSBezierPath] {
//        let beziers = self.convertBeziers()
//
//    }
    
//    func divide(with path: NSBezierPath) -> [NSBezierPath] {
//
//    }
    
    // ★★★ Get Union Path ★★★
    func or(_ path: NSBezierPath) -> [NSBezierPath] {
        if !self.bounds.intersects(path.bounds) {
            return [self, path]
        }
        let beziersA = self.convertBeziers()
        let beziersB = path.convertBeziers()
        return []
    }
    
    // ★★★ Get Intersection Path ★★★
    func and(_ path: NSBezierPath) -> [NSBezierPath] {
        if !self.bounds.intersects(path.bounds) {
            return []
        }
        let beziersA = self.convertBeziers()
        let beziersB = path.convertBeziers()
        return []
    }
    
    // ★★★ Get Difference Path ★★★
    func not(_ path: NSBezierPath) -> [NSBezierPath] {
        if !self.bounds.intersects(path.bounds) {
            return [self]
        }
        let beziersA = self.convertBeziers()
        let beziersB = path.convertBeziers()
        return []
    }
    
    // ★★★ Get Symmetric Difference Path ★★★
    func xor(_ path: NSBezierPath) -> [NSBezierPath] {
        if !self.bounds.intersects(path.bounds) {
            return [self, path]
        }
        let beziersA = self.convertBeziers()
        let beziersB = path.convertBeziers()
        return []
    }
    
}
