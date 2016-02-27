// BasicTextCell.swift
// Copyright (c) 2016 Nathan Lampi (http://nathanlampi.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import UIKit
import SwiftGridView

public class BasicTextCell : SwiftGridCell {
    
    public var textLabel : UILabel!
    public var padding : CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initCell()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initCell()
    }
    
    private func initCell() {
        self.backgroundView = UIView()
        self.selectedBackgroundView = UIView()
        self.selectedBackgroundView?.backgroundColor = UIColor.orangeColor()
        
        self.padding = 8.0
        self.textLabel = UILabel.init(frame: self.frame)
        
        self.textLabel.textColor = UIColor.blackColor()
        self.textLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.textLabel)
        
        let views = ["tL": self.textLabel]
        let metrics = ["p": self.padding]
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-p-[tL]-p-|",
            options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: metrics, views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[tL]|",
            options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: metrics, views: views))
    }
    
    public override class func reuseIdentifier() -> String {
        
        return "BasicCellReuseId"
    }
}