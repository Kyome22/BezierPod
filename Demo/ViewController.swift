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
    @IBOutlet weak var modePopUp: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    @IBAction func select(_ sender: NSPopUpButton) {
        bezierView.select(sender.indexOfSelectedItem)
    }

}

