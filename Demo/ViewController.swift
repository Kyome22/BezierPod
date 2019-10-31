//
//  ViewController.swift
//  Demo
//
//  Created by Takuto Nakamura on 2019/05/22.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var bezierView: BezierView!
    @IBOutlet weak var toggleBtn: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: NSColor.black,
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: 16)
        ]
        toggleBtn.attributedTitle = NSAttributedString(string: "Interactive", attributes: attributes)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func toggle(_ sender: NSButton) {
        bezierView.toggle(sender.state == NSControl.StateValue.on)
    }
}

