// SwiftGridReusableView.swift
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

public protocol SwiftGridReusableViewDelegate {
    func swiftGridReusableView(reusableView: SwiftGridReusableView, didSelectViewAtIndexPath indexPath: NSIndexPath)
    func swiftGridReusableView(reusableView: SwiftGridReusableView, didDeselectViewAtIndexPath indexPath: NSIndexPath)
    func swiftGridReusableView(reusableView: SwiftGridReusableView, didHighlightViewAtIndexPath indexPath: NSIndexPath)
    func swiftGridReusableView(reusableView: SwiftGridReusableView, didUnhighlightViewAtIndexPath indexPath: NSIndexPath)
}


public class SwiftGridReusableView: UICollectionReusableView {
    public var selected:Bool = false {
        didSet {
            self.selectedBackgroundView?.hidden = !selected
        }
    }
    public var highlighted:Bool = false{
        didSet {
            self.selectedBackgroundView?.hidden = !highlighted
        }
    }
    internal var delegate:SwiftGridReusableViewDelegate?
    internal var elementKind: String = ""
    internal var indexPath:NSIndexPath = NSIndexPath.init() // TODO: Is there a better way to handle this?
    
    public var contentView:UIView = UIView()
    
    private var _backgroundView: UIView?
    public var backgroundView:UIView? {
        get {
            return _backgroundView
        }
        set(backgroundView) {
            _backgroundView?.removeFromSuperview()
            _backgroundView = nil
            _backgroundView = backgroundView!
            
            _backgroundView!.translatesAutoresizingMaskIntoConstraints = false
            if(self.selectedBackgroundView != nil) { // TODO: Simplify this logic?
                self.insertSubview(_backgroundView!, belowSubview: self.selectedBackgroundView!)
            } else {
                self.insertSubview(_backgroundView!, belowSubview: self.contentView)
            }
            
            let views = ["bV": _backgroundView!]
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[bV]|",
                options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: nil, views: views))
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[bV]|",
                options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: nil, views: views))
        }
    }
    
    
    private var _selectedBackgroundView: UIView?
    public var selectedBackgroundView:UIView? {
        get {
            return _selectedBackgroundView
        }
        set(selectedBackgroundView) {
            _selectedBackgroundView?.removeFromSuperview()
            _selectedBackgroundView = nil
            _selectedBackgroundView = selectedBackgroundView!
            _selectedBackgroundView!.hidden = true
            
            _selectedBackgroundView!.translatesAutoresizingMaskIntoConstraints = false
            self.insertSubview(_selectedBackgroundView!, belowSubview: self.contentView)
            
            let views = ["sbV": _selectedBackgroundView!]
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[sbV]|",
                options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: nil, views: views))
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[sbV]|",
                options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: nil, views: views))
            
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupDefaults()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupDefaults()
    }
    
    private func setupDefaults() {
        self.backgroundColor = UIColor.clearColor()
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)
        
        let views = ["cV": self.contentView]
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[cV]|",
            options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[cV]|",
            options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: nil, views: views))
    }
    
    
    // MARK: - Public Methods
    
    public class func reuseIdentifier() -> String {
        
        return "SwiftGridReusableViewReuseId"
    }
    
    
    // MARK: - Gesture Recognizer
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.toggleHighlighted(true)
    }
    
    override public func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        self.toggleHighlighted(false)
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.toggleHighlighted(false)
        self.toggleSelected(!self.selected)
    }
    
    private func toggleHighlighted(highlighted: Bool) {
        self.highlighted = highlighted
        
        if(highlighted) {
            self.delegate?.swiftGridReusableView(self, didHighlightViewAtIndexPath: self.indexPath)
        } else {
            self.delegate?.swiftGridReusableView(self, didUnhighlightViewAtIndexPath: self.indexPath)
        }
    }
    
    private func toggleSelected(selected: Bool) {
        self.selected = selected
        
        if(selected) {
            self.delegate?.swiftGridReusableView(self, didSelectViewAtIndexPath: self.indexPath)
        } else {
            self.delegate?.swiftGridReusableView(self, didDeselectViewAtIndexPath: self.indexPath)
        }
    }
    
    
    // MARK: - Cell Reuse
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        self.selectedBackgroundView?.hidden = true
        self.indexPath = NSIndexPath.init()
        self.selected = false
        self.highlighted = false
    }
}