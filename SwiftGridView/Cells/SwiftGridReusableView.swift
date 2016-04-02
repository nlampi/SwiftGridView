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

// MARK: - SwiftGridReusableViewDelegate

/**
 The `SwiftGridReusableViewDelegate` is used for passing selection and highlighting events through to the data grid.
 */
public protocol SwiftGridReusableViewDelegate {
    /**
     Called when the reusable view is selected.
     
     - Parameter reusableView: The reusable view instance.
     - Parameter indexpath: The swift grid view index path of the passed reusable view.
     */
    func swiftGridReusableView(reusableView: SwiftGridReusableView, didSelectViewAtIndexPath indexPath: NSIndexPath)
    
    /**
     Called when the reusable view is deselected.
     
     - Parameter reusableView: The reusable view instance.
     - Parameter indexpath: The swift grid view index path of the passed reusable view.
     */
    func swiftGridReusableView(reusableView: SwiftGridReusableView, didDeselectViewAtIndexPath indexPath: NSIndexPath)
    
    /**
     Called when the reusable view is highlighted.
     
     - Parameter reusableView: The reusable view instance.
     - Parameter indexpath: The swift grid view index path of the passed reusable view.
     */
    func swiftGridReusableView(reusableView: SwiftGridReusableView, didHighlightViewAtIndexPath indexPath: NSIndexPath)
    
    /**
     Called when the reusable view is unhighlighted.
     
     - Parameter reusableView: The reusable view instance.
     - Parameter indexpath: The swift grid view index path of the passed reusable view.
     */
    func swiftGridReusableView(reusableView: SwiftGridReusableView, didUnhighlightViewAtIndexPath indexPath: NSIndexPath)
}

/**
 `SwiftGridReusableView` is the primary reusable view used for headers and footers in the `SwiftGridView`
 */
public class SwiftGridReusableView: UICollectionReusableView {
    
    // MARK: - Properties
    
    internal var delegate:SwiftGridReusableViewDelegate?
    internal var elementKind: String = ""
    internal var indexPath:NSIndexPath = NSIndexPath.init() // TODO: Is there a better way to handle this?
    
    /// Views become highlighted when the user touches them.
    public var highlighted:Bool = false{
        didSet {
            self.selectedBackgroundView?.hidden = !highlighted
        }
    }
    
    // The selected state is toggled when the user lifts up from a highlighted view.
    public var selected:Bool = false {
        didSet {
            self.selectedBackgroundView?.hidden = !selected
        }
    }
    
    /// Add custom subviews to the reusable view's content view.
    public var contentView:UIView = UIView()
    
    /// The background view is a subview behind all other views.
    public var backgroundView:UIView? {
        willSet {
            self.backgroundView?.removeFromSuperview()
            self.backgroundView = nil
        }
        didSet {
            self.backgroundView!.translatesAutoresizingMaskIntoConstraints = false
            
            if(self.selectedBackgroundView != nil) { // TODO: Simplify this logic?
                self.insertSubview(self.backgroundView!, belowSubview: self.selectedBackgroundView!)
            } else {
                self.insertSubview(self.backgroundView!, belowSubview: self.contentView)
            }
            
            let views = ["bV": self.backgroundView!]
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[bV]|",
                options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: nil, views: views))
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[bV]|",
                options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: nil, views: views))
        }
    }
    
    /// The selectedBackgroundView will be placed above the background view and displayed on view selection.
    public var selectedBackgroundView:UIView? {
        willSet {
            self.selectedBackgroundView?.removeFromSuperview()
            self.selectedBackgroundView = nil
        }
        didSet {
            self.selectedBackgroundView!.hidden = true
            
            self.selectedBackgroundView!.translatesAutoresizingMaskIntoConstraints = false
            self.insertSubview(self.selectedBackgroundView!, belowSubview: self.contentView)
            
            let views = ["sbV": self.selectedBackgroundView!]
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[sbV]|",
                options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: nil, views: views))
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[sbV]|",
                options: NSLayoutFormatOptions.DirectionLeftToRight, metrics: nil, views: views))
        }
    }
    
    // MARK: - Init
    
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
    
    /**
     Returns the reuse identifier string to be used for the cell. Override to provide a custom identifier.
     
     - Returns: String identifier for the cell.
     */
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
    
    /// Called before instance is returned from the reuse queue.
    /// Subclasses must call super.
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        self.selectedBackgroundView?.hidden = true
        self.indexPath = NSIndexPath.init()
        self.selected = false
        self.highlighted = false
    }
}