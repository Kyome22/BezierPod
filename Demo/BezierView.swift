//
//  BezierView.swift
//  Demo
//
//  Created by Takuto Nakamura on 2019/05/22.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import Cocoa
import BezierPod

class BezierView: NSView {
    
    var w: CGFloat { return self.bounds.width }
    var h: CGFloat { return self.bounds.height }
    var r: CGFloat = 3.0
    var points = [NSPoint]()
    var currentPoint: Int = -1
    var isInteractive: Bool = true
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layer?.backgroundColor = CGColor.white
        points.append(NSPoint(x: 0.34 * w, y: 0.16 * h))
        points.append(NSPoint(x: 0.17 * w, y: 0.57 * h))
        points.append(NSPoint(x: 0.8 * w, y: 0.39 * h))
        points.append(NSPoint(x: 0.73 * w, y: 0.77 * h))
        points.append(NSPoint(x: 0.45 * w, y: 0.91 * h))
    }
    
    override func mouseDown(with event: NSEvent) {
        let cursor = event.locationInWindow
        for n in (0 ..< 5) {
            if cursor.length(from: points[n]) < r {
                currentPoint = n
                return
            }
        }
        currentPoint = -1
    }
    
    override func mouseDragged(with event: NSEvent) {
        if currentPoint < 0 { return }
        points[currentPoint] = event.locationInWindow
        self.layer?.setNeedsDisplay()
    }
    
    func toggle(_ flag: Bool) {
        isInteractive = flag
        self.layer?.setNeedsDisplay()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if isInteractive{
            drawInteractive()
        } else {
            drawNonInteractive()
        }
    }
    
    func drawNonInteractive() {
        let bezier = NSBezierPath()
        NSColor.gray.set()
        bezier.lineWidth = 2.0
        bezier.move(to: NSPoint(x: 90.0, y: 80.0))
        bezier.line(to: NSPoint(x: 400.0, y: 330.0))
        bezier.line(to: NSPoint(x: 300.0, y: 350.0))
        bezier.curve(to: NSPoint(x: 220.0, y: 210.0),
                     controlPoint1: NSPoint(x: 400.0, y: 170.0),
                     controlPoint2: NSPoint(x: 80.0, y: 450.0))
        bezier.line(to: NSPoint(x: 110.0, y: 180.0))
        bezier.close()
        
        drawLookUpTable(bezier)
        drawOffset(bezier, 30.0, NSColor.red)
        drawOffset(bezier, -18.0, NSColor.blue)
    }
    
    func drawInteractive() {
        let bezier = NSBezierPath()
        NSColor.blue.setStroke()
        bezier.lineWidth = 3.0
        bezier.move(to: points[0])
        bezier.curve(to: points[3],
                     controlPoint1: points[1],
                     controlPoint2: points[2])
        bezier.line(to: points[4])
        drawControlLine()
        drawLookUpTable(bezier)

        // Test you want to
        drawOffset(bezier, 20.0, NSColor.red)
        drawOffset(bezier, -20.0, NSColor.blue)
        
        drawControlPoint()
    }
    
    func drawControlLine() {
        let path = NSBezierPath()
        path.lineWidth = 2.0
        NSColor.cyan.setStroke()
        path.move(to: points[0])
        path.line(to: points[1])
        path.stroke()
        path.removeAllPoints()
        path.move(to: points[3])
        path.line(to: points[2])
        path.stroke()
    }
    
    func drawControlPoint() {
        let path = NSBezierPath()
        NSColor.gray.setStroke()
        for i in (0 ..< 5) {
            path.removeAllPoints()
            path.appendOval(in: NSRect(origin: points[i] - CGPoint(r), size: CGSize(2 * r)))
            path.stroke()
        }
    }
    
    func drawDot(_ p: NSPoint, _ color: NSColor) {
        let point = NSBezierPath(ovalIn: NSRect(origin: p - CGPoint(r), size: CGSize(2 * r)))
        color.setFill()
        point.fill()
    }
    
    func drawLing(_ p: NSPoint, _ color: NSColor) {
        let point = NSBezierPath(ovalIn: NSRect(origin: p - CGPoint(r), size: CGSize(2 * r)))
        color.setStroke()
        point.stroke()
    }
    
    func drawLookUpTable(_ path: NSBezierPath) {
        let table = path.getLookUpTable(density: 0.2)
        for (n, p) in table.enumerated() {
            let dot = NSBezierPath(ovalIn: NSRect(origin: p - CGPoint(1), size: CGSize(2)))
            NSColor(hue: CGFloat(n) / CGFloat(table.count)).set()
            dot.fill()
        }
    }
    
    func drawBounds(_ path: NSBezierPath) {
        let rect = path.bounds
        NSColor.red.setStroke()
        path.lineWidth = 1.0
        path.removeAllPoints()
        path.appendRect(rect)
        path.stroke()
    }
    
    func drawSplitSegment(_ path: NSBezierPath) {
        if let segment = path.getSplitSegment(0.2, 0.9) {
            segment.lineWidth = 4.5
            NSColor.purple.setStroke()
            segment.stroke()
        }
    }
    
    func drawOffset(_ path: NSBezierPath, _ distance: CGFloat, _ color: NSColor) {
        let offsetPath = path.offset(distance)
        color.setStroke()
        for (n, bezier) in offsetPath.enumerated() {
//            bezier.lineWidth = 0.5
            // NSColor(hue: CGFloat(n) / CGFloat(offsetPath.count)).set()
            bezier.stroke()
        }
    }
    
    func drawLineIntersects(_ path: NSBezierPath, _ line: Line) {
        let intersects: [NSPoint] = path.getLineIntersects(line)
        NSColor.yellow.setStroke()
        intersects.forEach { (p) in
            let point = NSBezierPath(ovalIn: NSRect(origin: p - CGPoint(r), size: CGSize(2 * r)))
            point.lineWidth = 2.0
            point.stroke()
        }
    }
    
    func drawSelfIntersects(_ path: NSBezierPath) {
        let intersects = path.getSelfIntersects()
        NSColor.red.setStroke()
        intersects.forEach { (p) in
            let point = NSBezierPath(ovalIn: NSRect(origin: p - CGPoint(r), size: CGSize(2 * r)))
            point.lineWidth = 2.0
            point.stroke()
        }
    }
    
    func drawCurveIntersects(_ path1: NSBezierPath, _ path2: NSBezierPath) {
        let intersects = path1.getCurveIntersects(path2)
        NSColor.yellow.setStroke()
        intersects.forEach { (p) in
            let point = NSBezierPath(ovalIn: NSRect(origin: p - CGPoint(r), size: CGSize(2 * r)))
            point.lineWidth = 2.0
            point.stroke()
        }
    }
    
//    func drawDistance() {
//        let bezier = Curve(points: points)
//        let d = bezier.distance(from: target)
//        let p = bezier.compute(d.t)
//        let path = NSBezierPath()
//        path.move(to: target)
//        path.line(to: p)
//        path.stroke()
//        Swift.print(d.value)
//    }
    
}
