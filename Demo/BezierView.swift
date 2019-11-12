//
//  BezierView.swift
//  Demo
//
//  Created by Takuto Nakamura on 2019/05/22.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import Cocoa
import BezierPod

enum Mode: Int {
    case offsetInterective
    case offsetNoninterective
    case or
    case and
    case not
    case xor
}

class BezierView: NSView {
    
    var w: CGFloat { return self.bounds.width }
    var h: CGFloat { return self.bounds.height }
    var r: CGFloat = 3.0
    var points = [NSPoint]()
    var currentPoint: Int = -1
    var mode = Mode.offsetInterective
    
    let targets = [NSPoint(x: 163.20000000000002, y: 76.8),
                   NSPoint(x: 81.60000000000001, y: 273.59999999999997),
                   NSPoint(x: 675.84375, y: 460.3828125),
                   NSPoint(x: 350.4, y: 369.6),
                   NSPoint(x: 216.0, y: 436.8)]
    
    let targets3 = [NSPoint(x: 163.20000000000002, y: 76.8),
                    NSPoint(x: 400.33984375, y: 72.55859375),
                    NSPoint(x: 508.1796875, y: 126.53515625),
                    NSPoint(x: 350.4, y: 369.6),
                    NSPoint(x: 216.0, y: 436.8)]
    
    let targets2 = [NSPoint(x: 337.5401773395534, y:352.6308170901928),
                    NSPoint(x: 336.56233542524456,y: 354.15815251237984)]


    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layer?.backgroundColor = CGColor.white
        points = targets3
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
    
    func select(_ id: Int) {
        mode = Mode(rawValue: id)!
        self.layer?.setNeedsDisplay()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        switch mode {
        case .offsetInterective: drawInteractive()
        case .offsetNoninterective: drawNonInteractive()
        case .or: drawOr()
        case .and: drawAnd()
        case .not: drawNot()
        case .xor: drawXor()
        }
    }
    
    func drawNonInteractive() {
        let bezier = NSBezierPath()
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
        bezier.lineWidth = 3.0
        bezier.move(to: points[0])
        bezier.curve(to: points[3],
                     controlPoint1: points[1],
                     controlPoint2: points[2])
        bezier.line(to: points[4])
        drawControlLine()
        drawLookUpTable(bezier)
        
        // Test you want to
//        drawOffset(bezier, 20.0, NSColor.red)
        drawOffset(bezier, -20.0)
        
        drawControlPoint()
//        targets2.forEach { (p) in
//               drawLing(p, NSColor.black)
//           }
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
        Swift.print(points)
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
    
    func draw05() {
        let curve = Curve(points: [points[0], points[1], points[2], points[3]])
        drawLing(curve.compute(0.5), NSColor.orange)
    }
        
    func drawOffset(_ path: NSBezierPath, _ distance: CGFloat, _ color: NSColor) {
        let offsetPath = path.offset(distance)
        color.setStroke()
        offsetPath.forEach { (bezier) in
            bezier.lineWidth = 0.5
            bezier.stroke()
        }
    }
    
    func drawOffset(_ path: NSBezierPath, _ distance: CGFloat) {
        let offsetPath = path.offset(distance)
        for (n, bezier) in offsetPath.enumerated() {
            if n % 2 == 0 {
                NSColor.red.setStroke()
            } else {
                NSColor.blue.setStroke()
            }
//            NSColor(hue: CGFloat(n) / CGFloat(offsetPath.count)).set()
            bezier.lineWidth = 0.5
            bezier.stroke()
        }
    }
    
    func makeAB() -> (bezierA: NSBezierPath, bezierB: NSBezierPath) {
        let bezierA = NSBezierPath(roundedRect: NSRect(x: 50, y: 100, width: 300, height: 200),
                                   xRadius: 50,
                                   yRadius: 80)
        let bezierB = NSBezierPath()
        bezierB.move(to: NSPoint(x: 150, y: 150))
        bezierB.line(to: NSPoint(x: 400, y: 150))
        bezierB.line(to: NSPoint(x: 400, y: 350))
        bezierB.line(to: NSPoint(x: 200, y: 350))
        bezierB.line(to: NSPoint(x: 230, y: 250))
        bezierB.line(to: NSPoint(x: 330, y: 250))
        bezierB.line(to: NSPoint(x: 330, y: 200))
        bezierB.line(to: NSPoint(x: 100, y: 200))
        bezierB.close()
        return (bezierA, bezierB)
    }
    
    func drawOr() {

    }
    
    func drawAnd() {
        
    }
    
    func drawNot() {
        
    }
    
    func drawXor() {
        
    }
}
