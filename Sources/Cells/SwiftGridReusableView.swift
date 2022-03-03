// SwiftGridReusableView.swift
// Copyright (c) 2016 - Present Nathan Lampi (http://nathanlampi.com/)
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
public protocol SwiftGridReusableViewDelegate: AnyObject {
    /**
     Called when the reusable view is selected.
     
     - Parameter reusableView: The reusable view instance.
     - Parameter indexpath: The swift grid view index path of the passed reusable view.
     */
    func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didSelectViewAtIndexPath indexPath: IndexPath)
    
    /**
     Called when the reusable view is deselected.
     
     - Parameter reusableView: The reusable view instance.
     - Parameter indexpath: The swift grid view index path of the passed reusable view.
     */
    func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didDeselectViewAtIndexPath indexPath: IndexPath)
    
    /**
     Called when the reusable view is highlighted.
     
     - Parameter reusableView: The reusable view instance.
     - Parameter indexpath: The swift grid view index path of the passed reusable view.
     */
    func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didHighlightViewAtIndexPath indexPath: IndexPath)
    
    /**
     Called when the reusable view is unhighlighted.
     
     - Parameter reusableView: The reusable view instance.
     - Parameter indexpath: The swift grid view index path of the passed reusable view.
     */
    func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didUnhighlightViewAtIndexPath indexPath: IndexPath)
}


/**
 `SwiftGridReusableView` is the primary reusable view used for headers and footers in the `SwiftGridView`
 */
open class SwiftGridReusableView: UICollectionReusableView {
    
    // MARK: - Properties
    
    internal weak var delegate:SwiftGridReusableViewDelegate?
    internal var elementKind: String = ""
    internal var indexPath:IndexPath = IndexPath.init() // TODO: Is there a better way to handle this?
    
    /// Views become highlighted when the user touches them.
    open var highlighted:Bool = false {
        didSet {
            self.selectedBackgroundView?.isHidden = !highlighted
        }
    }
    
    // The selected state is toggled when the user lifts up from a highlighted view.
    open var selected:Bool = false {
        didSet {
            self.selectedBackgroundView?.isHidden = !selected
        }
    }
    
    /// Add custom subviews to the reusable view's content view.
    open var contentView:UIView = UIView()
    
    /// The background view is a subview behind all other views.
    @IBOutlet open var backgroundView:UIView? {
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
                self.sendSubviewToBack(self.backgroundView!)
            }
            
            let views = ["bV": self.backgroundView!]
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[bV]|",
                options: NSLayoutConstraint.FormatOptions.directionLeftToRight, metrics: nil, views: views))
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[bV]|",
                options: NSLayoutConstraint.FormatOptions.directionLeftToRight, metrics: nil, views: views))
        }
    }
    
    /// The selectedBackgroundView will be placed above the background view and displayed on view selection.
    @IBOutlet open var selectedBackgroundView:UIView? {
        willSet {
            self.selectedBackgroundView?.removeFromSuperview()
            self.selectedBackgroundView = nil
        }
        didSet {
            self.selectedBackgroundView!.isHidden = true
            
            self.selectedBackgroundView!.translatesAutoresizingMaskIntoConstraints = false
            self.insertSubview(self.selectedBackgroundView!, belowSubview: self.contentView)
            self.sendSubviewToBack(self.selectedBackgroundView!)
            
            if self.backgroundView != nil {
                self.sendSubviewToBack(self.backgroundView!)
            }
            
            let views = ["sbV": self.selectedBackgroundView!]
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[sbV]|",
                options: NSLayoutConstraint.FormatOptions.directionLeftToRight, metrics: nil, views: views))
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[sbV]|",
                options: NSLayoutConstraint.FormatOptions.directionLeftToRight, metrics: nil, views: views))
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
    
    fileprivate func setupDefaults() {
        self.backgroundColor = UIColor.clear
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)
        
        let views = ["cV": self.contentView]
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[cV]|",
            options: NSLayoutConstraint.FormatOptions.directionLeftToRight, metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[cV]|",
            options: NSLayoutConstraint.FormatOptions.directionLeftToRight, metrics: nil, views: views))
    }
    
    
    // MARK: - Public Methods
    
    /**
     Returns the reuse identifier string to be used for the cell. Override to provide a custom identifier.
     
     - Returns: String identifier for the cell.
     */
    open class func reuseIdentifier() -> String {
        
        return "SwiftGridReusableViewReuseId"
    }
    
    
    // MARK: - Gesture Recognizer
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.toggleHighlighted(true)
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.toggleHighlighted(false)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.toggleHighlighted(false)
        self.toggleSelected(!self.selected)
    }
    
    fileprivate func toggleHighlighted(_ highlighted: Bool) {
        self.highlighted = highlighted
        
        if(highlighted) {
            self.delegate?.swiftGridReusableView(self, didHighlightViewAtIndexPath: self.indexPath)
        } else {
            self.delegate?.swiftGridReusableView(self, didUnhighlightViewAtIndexPath: self.indexPath)
        }
    }
    
    fileprivate func toggleSelected(_ selected: Bool) {
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
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        self.selectedBackgroundView?.isHidden = true
        self.indexPath = IndexPath.init()
        self.selected = false
        self.highlighted = false
    }
}
