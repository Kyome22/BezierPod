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
    
    let targets = [NSPoint(x: 167.97425781169247, y: 116.65168998459133),
                   NSPoint(x: 174.70825101490303, y: 101.05232038247621),
                   NSPoint(x: 170.15780433581594, y: 111.6449499852259),
                   NSPoint(x: 160.7690639111568,  y: 132.7807038823869),
                   NSPoint(x: 152.8809554002186,  y: 149.62129343800734),
                   NSPoint(x: 148.69235052851224, y: 158.19193001181372),
                   NSPoint(x: 148.5500606656322,  y: 147.58241072923138),
                   NSPoint(x: 138.47906657196657, y: 135.10384970308422),
                   NSPoint(x: 119.73629222779181, y: 135.32348078477781),
                   NSPoint(x: 118.945651479204,   y: 135.12990019187805),
                   NSPoint(x: 126.65845670567587, y: 128.4948211502038),
                   NSPoint(x: 181.1609983199312,  y: 119.97777287016453),
                   NSPoint(x: 257.0686988918057,  y: 237.81299010580838),
                   NSPoint(x: 260.6853202649189,  y: 249.42205125896513),
                   NSPoint(x: 261.95672391521975, y: 253.6327953356461),
                   NSPoint(x: 261.34416396769313, y: 257.9884357285148)]

    let targets2 = [NSPoint(x: 163.2, y: 76.8),
                   NSPoint(x: 81.6, y: 273.6),
                   NSPoint(x: 162.796875, y: -5.58203125),
                   NSPoint(x: 220.79296875, y: 280.47265625),
                   NSPoint(x: 216.0, y: 436.8)]
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layer?.backgroundColor = CGColor.white
        points = targets2
//        points.append(NSPoint(x: 0.34 * w, y: 0.16 * h))
//        points.append(NSPoint(x: 0.17 * w, y: 0.57 * h))
//        points.append(NSPoint(x: 0.8 * w, y: 0.39 * h))
//        points.append(NSPoint(x: 0.73 * w, y: 0.77 * h))
//        points.append(NSPoint(x: 0.45 * w, y: 0.91 * h))
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
//        drawOffset(bezier, -20.0, NSColor.blue)
        
        drawControlPoint()
        // drawDot(NSPoint(x: 157.26590956365396, y: 148.00400307691643), NSColor.red)
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
        Swift.print(points[3])
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
//        color.setStroke()
        for (n, bezier) in offsetPath.enumerated() {
            bezier.lineWidth = 0.5
            if n % 2 == 0 {
                NSColor.black.set()
            } else {
                NSColor.green.set()
            }
//            NSColor(hue: CGFloat(n) / CGFloat(offsetPath.count)).set()
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
