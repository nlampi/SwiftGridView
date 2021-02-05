// SwiftGridView.swift
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

/// String identifier for Header elements
public let SwiftGridElementKindHeader: String = "SwiftGridElementKindHeader"
/// String identifier for Grouped Header elements
public let SwiftGridElementKindGroupedHeader: String = "SwiftGridElementKindGroupedHeader"
/// String identifier for Section Header elements
public let SwiftGridElementKindSectionHeader: String = UICollectionView.elementKindSectionHeader
/// String identifier for Footer elements
public let SwiftGridElementKindFooter: String = "SwiftGridElementKindFooter"
/// String identifier for Section Footer elements
public let SwiftGridElementKindSectionFooter: String = UICollectionView.elementKindSectionFooter


// MARK: - SwiftGridView Class

/**
 `SwiftGridView` is the primary view class, utilizing a UICollectionView and a custom layout handler.
 */
open class SwiftGridView : UIView, UICollectionViewDataSource, UICollectionViewDelegate, SwiftGridLayoutDelegate, SwiftGridReusableViewDelegate {
    
    // MARK: - Init
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initDefaults()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initDefaults()
    }
    
    fileprivate func initDefaults() {
        sgCollectionViewLayout = SwiftGridLayout()
        
        // FIXME: Use constraints!?
        self.collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: sgCollectionViewLayout)
        self.collectionView.dataSource = self // TODO: Separate DataSource/Delegate?
        self.collectionView.delegate = self
        self.collectionView.backgroundColor = self.backgroundColor
        self.collectionView.allowsMultipleSelection = true
        
        self.addSubview(self.collectionView)
    }
    
    
    // MARK: - Public Properties
    
    /**
     Internal Collectionview. Open to allow for custom interaction, modify at own risk.
     */
    @objc open internal(set) var collectionView: UICollectionView!
    
    #if TARGET_INTERFACE_BUILDER
    /// Allows IBOutlets to work properly.
    /// Required dataSource  link of type `SwiftGridViewDataSource`
    @IBOutlet open weak var dataSource: AnyObject?
    /// Allows IBOutlets to work properly.
    /// Required delegate link of type `SwiftGridViewDelegate`
    @IBOutlet open weak var delegate: AnyObject?
    #else
    /// Required dataSource  link of type `SwiftGridViewDataSource`
    @objc open weak var dataSource: SwiftGridViewDataSource?
    /// Required delegate link of type `SwiftGridViewDelegate`
    @objc open weak var delegate: SwiftGridViewDelegate?
    #endif
    
    /// Enable or disable selection for the entire gridview.
    @objc open var allowsSelection: Bool {
        set(allowsSelection) {
            self.collectionView.allowsSelection = allowsSelection
        }
        get {
            return self.collectionView.allowsSelection
        }
    }
    
    /// When enabled, multiple cells can be selected. If row selection is enabled, then multiple rows can be selected.
    @objc open var allowsMultipleSelection: Bool = false
    
    /// If row selection is enabled, then entire rows will be selected rather than individual cells. This applies to section headers/footers in addition to rows.
    @objc open var rowSelectionEnabled: Bool = false
    
    /// When directional lock is enabled, the grid is only scrollable in one direction at a time (vertically or horizontally)
    @objc open var isDirectionalLockEnabled: Bool {
        set(isDirectionalLockEnabled) {
            self.collectionView.isDirectionalLockEnabled = isDirectionalLockEnabled
        }
        get {
            return self.collectionView.isDirectionalLockEnabled
        }
    }
    
    /// Enables bouncing for the gridvies
    @objc open var bounces: Bool {
        set(bounces) {
            self.collectionView.bounces = bounces
        }
        get {
            return self.collectionView.bounces
        }
    }
    
    /// Determines whether section headers will stick while scrolling vertically or scroll off screen.
    @objc open var stickySectionHeaders: Bool {
        set(stickySectionHeaders) {
            self.sgCollectionViewLayout.stickySectionHeaders = stickySectionHeaders
        }
        get {
            return self.sgCollectionViewLayout.stickySectionHeaders
        }
    }
    
    /// default NO. if YES and bounces is YES, even if content is smaller than bounds, allow drag vertically
    @objc open var alwaysBounceVertical: Bool {
        set(alwaysBounceVertical) {
            self.collectionView.alwaysBounceVertical = alwaysBounceVertical
        }
        get {
            return self.collectionView.alwaysBounceVertical
        }
    }
    
    /// default NO. if YES and bounces is YES, even if content is smaller than bounds, allow drag horizontally
    @objc open var alwaysBounceHorizontal: Bool {
        set(alwaysBounceHorizontal) {
            self.collectionView.alwaysBounceHorizontal = alwaysBounceHorizontal
        }
        get {
            return self.collectionView.alwaysBounceHorizontal
        }
    }
    
    /**
     A Boolean value that controls whether the horizontal scroll indicator is visible.
     The default value is true. The indicator is visible while tracking is underway and fades out after tracking.
    */
    @objc open var showsHorizontalScrollIndicator: Bool {
        set(showsHorizontalScrollIndicator) {
            self.collectionView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        }
        get {
            return self.collectionView.showsHorizontalScrollIndicator
        }
    }
    
    /**
     A Boolean value that controls whether the vertical scroll indicator is visible.
     The default value is true. The indicator is visible while tracking is underway and fades out after tracking.
     */
    @objc open var showsVerticalScrollIndicator: Bool {
        set(showsVerticalScrollIndicator) {
            self.collectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        }
        get {
            return self.collectionView.showsVerticalScrollIndicator
        }
    }
    
    /// Pinch to expand increases the size of the columns. Experimental feature.
    @objc open var pinchExpandEnabled: Bool = false {
        didSet {
            if(!self.pinchExpandEnabled) {
                self.collectionView.removeGestureRecognizer(self.sgPinchGestureRecognizer)
                self.collectionView.removeGestureRecognizer(self.sgTwoTapGestureRecognizer)
            } else {
                self.collectionView.addGestureRecognizer(self.sgPinchGestureRecognizer)
                self.sgTwoTapGestureRecognizer.numberOfTouchesRequired = 2
                self.collectionView.addGestureRecognizer(self.sgTwoTapGestureRecognizer)
            }
        }
    }
    
    /// - Returns: YES if user has touched. may not yet have started draggin
    @objc open var isTracking: Bool {
        get {
            return self.collectionView.isTracking
        }
    }
    
    /// - Returns: YES if user has started scrolling. this may require some time and or distance to move to initiate dragging
    @objc open var isDragging: Bool {
        get {
            return self.collectionView.isDragging
        }
    }
    /// - Returns: YES if user isn't dragging (touch up) but scroll view is still moving
    @objc open var isDecelerating: Bool {
        get {
            return self.collectionView.isDecelerating
        }
    }
    
    /// Whether or not the gridView will automatically scroll to top when the status bar is tapped. Default is YES.
    @objc open var scrollsToTop: Bool {
        set(scrollsToTop) {
            self.collectionView.scrollsToTop = scrollsToTop
        }
        get {
            return self.collectionView.scrollsToTop
        }
    }
    
    @available(iOS 10.0, *)
    @objc open var refreshControl: UIRefreshControl? {
        set(refreshControl) {
            self.collectionView.refreshControl = refreshControl
        }
        get {
            return self.collectionView.refreshControl
        }
    }
    
    
    // MARK: - Private Variables
    
    fileprivate var sgCollectionViewLayout: SwiftGridLayout!
    fileprivate lazy var sgPinchGestureRecognizer:UIPinchGestureRecognizer = UIPinchGestureRecognizer.init(target: self, action: #selector(SwiftGridView.handlePinchGesture(_:)))
    fileprivate lazy var sgTwoTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(SwiftGridView.handleTwoFingerTapGesture(_:)))
    
    fileprivate var _sgSectionCount: Int = 0
    fileprivate var sgSectionCount: Int {
        get {
            if(_sgSectionCount == 0) {
                _sgSectionCount = self.dataSource!.numberOfSectionsInDataGridView(self)
            }
            
            return _sgSectionCount
        }
    }
    
    fileprivate var _sgColumnCount: Int = 0
    fileprivate var sgColumnCount: Int {
        get {
            if(_sgColumnCount == 0) {
                _sgColumnCount = self.dataSource!.numberOfColumnsInDataGridView(self)
            }
            
            return _sgColumnCount
        }
    }
    
    fileprivate var _sgColumnWidth: CGFloat = 0
    fileprivate var sgColumnWidth: CGFloat {
        get {
            if(_sgColumnWidth == 0) {
                
                for columnIndex in 0 ..< self.sgColumnCount {
                    _sgColumnWidth += self.delegate!.dataGridView(self, widthOfColumnAtIndex: columnIndex)
                }
            }
            
            return _sgColumnWidth
        }
    }
    
    fileprivate var _groupedColumns: [[Int]]?
    fileprivate var groupedColumns: [[Int]] {
        get {
            if _groupedColumns == nil {
                if let groupedColumns = self.dataSource?.columnGroupingsForDataGridView?(self) {
                    _groupedColumns = groupedColumns
                } else {
                    _groupedColumns = [[Int]]()
                }
            }
            
            return _groupedColumns!
        }
    }
    
    // Cache selected items.
    fileprivate var selectedHeaders: NSMutableDictionary = NSMutableDictionary()
    fileprivate var selectedGroupedHeaders: NSMutableDictionary = NSMutableDictionary()
    fileprivate var selectedSectionHeaders: NSMutableDictionary = NSMutableDictionary()
    fileprivate var selectedSectionFooters: NSMutableDictionary = NSMutableDictionary()
    fileprivate var selectedFooters: NSMutableDictionary = NSMutableDictionary()
    
    
    // MARK: - Layout Subviews
    
    // TODO: Is this how resize should be handled?
    @objc open override func layoutSubviews() {
        super.layoutSubviews()
        
        if(self.collectionView.frame != self.bounds) {
            self.collectionView.frame = self.bounds
        }
    }
    
    
    // MARK: - Public Methods
    
    /**
     Reloads all data for the `SwiftGridView`
     */
    @objc open func reloadData(_ resetSize:Bool = true) {
        _sgSectionCount = 0
        _sgColumnCount = 0
        _sgColumnWidth = 0
        _groupedColumns = nil
        
        self.selectedHeaders = NSMutableDictionary()
        self.selectedGroupedHeaders = NSMutableDictionary()
        self.selectedSectionHeaders = NSMutableDictionary()
        self.selectedSectionFooters = NSMutableDictionary()
        self.selectedFooters = NSMutableDictionary()
        
        sgCollectionViewLayout.resetCachedParameters(resetSize)
        
        self.collectionView.reloadData()
        
        // Adjust offset to not overflow content area based on viewsize
        var contentOffset = self.collectionView.contentOffset
        if self.sgCollectionViewLayout.collectionViewContentSize.height - contentOffset.y < self.collectionView.frame.size.height {
            contentOffset.y = self.sgCollectionViewLayout.collectionViewContentSize.height - self.collectionView.frame.size.height
            
            if contentOffset.y < 0 {
                contentOffset.y = 0
            }
            
            self.collectionView.setContentOffset(contentOffset, animated: false)
        }
    }
    
    /**
     Reloads the specified items by their indexPath(s).
     - Parameter indexPaths: Array of `IndexPath` to reload
     - Parameter animated: Whether to animate the change or not
     */
    @objc open func reloadCellsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool) {
        self.reloadCellsAtIndexPaths(indexPaths, animated: animated, completion: nil)
    }
    
    /**
     Reloads the specified items by their indexPath(s).
     - Parameter indexPaths: Array of `IndexPath` to reload
     - Parameter animated: Whether to animate the change or not
     - Parameter completion: Completion handler executed upon reload
    */
    @objc open func reloadCellsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool, completion: ((Bool) -> Void)?) {
        let convertedPaths = self.reverseIndexPathConversionForIndexPaths(indexPaths)
        
        if(animated) {
            self.collectionView.performBatchUpdates({
                self.collectionView.reloadItems(at: convertedPaths)
                }, completion: { completed in
                    completion?(completed)
            })
        } else {
            self.collectionView.reloadItems(at: convertedPaths)
            completion?(true) // TODO: Fix!
        }
    }
    
    /**
     Get the item indexPath based on the provided point
     - Parameter point: `CGPoint` to search for
     - Returns: The indexPath for the appropriate item if it exists
     */
    @objc open func indexPathForItem(at point: CGPoint) -> IndexPath? {
        if let cvIndexPath: IndexPath = self.collectionView.indexPathForItem(at: point) {
            let convertedPath: IndexPath = self.convertCVIndexPathToSGIndexPath(cvIndexPath)
            
            return convertedPath
        }
        // Look at nearest path?
        return nil
    }
    
    /**
     Get the item indexPath for the provided cell
     - Parameter cell: Instance of `SwiftGridCell`
     - Returns: The indexPath for the appropriate item if it exists
     */
    @objc open func indexPath(for cell: SwiftGridCell) -> IndexPath? {
        if let cvIndexPath: IndexPath = self.collectionView.indexPath(for: cell) {
            let convertedPath: IndexPath = self.convertCVIndexPathToSGIndexPath(cvIndexPath)
            
            return convertedPath
        }
        
        return nil
    }
    
    /**
     Get the cell for the provided indexPath
     - Parameter indexPath: IndexPath to search for.
     - Returns: The `SwiftGridCell` instance for the provided indexPath
     */
    @objc open func cellForItem(at indexPath: IndexPath) -> SwiftGridCell? {
        let revertedPath: IndexPath = self.reverseIndexPathConversion(indexPath)
        let cell = self.collectionView.cellForItem(at: revertedPath) as? SwiftGridCell
        
        return cell
    }
    
    /**
     - Returns: Array of `SwiftGridCell` for all visibile cells.
     */
    @objc open var visibleCells: [SwiftGridCell] {
        get {
            let cells = self.collectionView.visibleCells as! [SwiftGridCell]
        
            return cells
        }
    }
    
    /**
    - Returns: Array of `IndexPath` for all visibile cells.
    */
    @objc open var indexPathsForVisibleItems: [IndexPath] {
        get {
            var indexPaths = [IndexPath]()
            for indexPath in self.collectionView.indexPathsForVisibleItems {
                let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
                indexPaths.append(convertedPath)
            }
            
            return indexPaths
        }
    }
    
    // FIXME: Doesn't work as intended.
//    public func reloadSupplementaryViewsOfKind(elementKind: String, atIndexPaths indexPaths: [NSIndexPath]) {
//        let convertedPaths = self.reverseIndexPathConversionForIndexPaths(indexPaths)
//        let context = UICollectionViewLayoutInvalidationContext()
//        context.invalidateSupplementaryElementsOfKind(elementKind, atIndexPaths: convertedPaths)
//            
//        self.sgCollectionViewLayout.invalidateLayoutWithContext(context)
//    }
    
    /// Register the provided class for row cell reuse within the `SwiftGridView`
    @objc(registerClass:forCellReuseIdentifier:)
    open func register(_ cellClass: Swift.AnyClass?, forCellWithReuseIdentifier identifier: String) {
        self.collectionView.register(cellClass, forCellWithReuseIdentifier:identifier)
    }
    
    /// Register the provided nib for row cell reuse within the `SwiftGridView`
    @objc open func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        self.collectionView.register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    /// Register the provided class for supplementary cell reuse within the `SwiftGridView`
    @objc(registerClass:forSupplementaryViewOfKind:withReuseIdentifier:)
    open func register(_ viewClass: Swift.AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
        self.collectionView.register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
    }
    
    /// Register the provided class for supplementary cell reuse within the `SwiftGridView`
    @objc open func register(_ nib: UINib?, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        self.collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }
    
    /// Dequeue Row Cell
    @objc open func dequeueReusableCellWithReuseIdentifier(_ identifier: String, forIndexPath indexPath: IndexPath!) -> SwiftGridCell {
        let revertedPath: IndexPath = self.reverseIndexPathConversion(indexPath)
        
        return self.collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: revertedPath) as! SwiftGridCell
    }
    
    /// Dequeue Supplementary Cell  by column
    @objc open func dequeueReusableSupplementaryViewOfKind(_ elementKind: String, withReuseIdentifier identifier: String, atColumn column: NSInteger) -> SwiftGridReusableView {
        let revertedPath: IndexPath = IndexPath(item: column, section: 0)
        
        return self.collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: revertedPath) as! SwiftGridReusableView
    }
    
    /// Dequeue Supplementary Cell  by `IndexPath`
    @objc open func dequeueReusableSupplementaryViewOfKind(_ elementKind: String, withReuseIdentifier identifier: String, forIndexPath indexPath: IndexPath) -> SwiftGridReusableView {
        let revertedPath: IndexPath = self.reverseIndexPathConversion(indexPath)
        
        return self.collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: revertedPath) as! SwiftGridReusableView
    }
    
    /// Selects the cell at the provided indexPath
    @objc open func selectCellAtIndexPath(_ indexPath:IndexPath, animated: Bool) {
        if(self.rowSelectionEnabled) {
            self.selectRowAtIndexPath(indexPath, animated: animated)
        } else {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            self.collectionView.selectItem(at: convertedPath, animated: animated, scrollPosition: UICollectionView.ScrollPosition())
        }
    }
    
    /// Deselects the cell at the provided indexPath
    @objc open func deselectCellAtIndexPath(_ indexPath:IndexPath, animated: Bool) {
        if(self.rowSelectionEnabled) {
            self.deselectRowAtIndexPath(indexPath, animated: animated)
        } else {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            self.collectionView.deselectItem(at: convertedPath, animated: animated)
        }
    }
    
    /// Select the section header at the provided indexPath
    @objc open func selectSectionHeaderAtIndexPath(_ indexPath:IndexPath) {
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath, selected: true)
        } else {
            self.selectReusableViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        }
    }
    
    /// Deselect the section header at the provided indexPath
    @objc open func deselectSectionHeaderAtIndexPath(_ indexPath:IndexPath) {
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath, selected: false)
        } else {
            self.deselectReusableViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        }
    }
    
    /// Select the section footer at the provided indexPath
    @objc open func selectSectionFooterAtIndexPath(_ indexPath:IndexPath) {
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath, selected: true)
        } else {
            self.selectReusableViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        }
    }
    
    /// Deselect the section footer at the provided indexPath
    @objc open func deselectSectionFooterAtIndexPath(_ indexPath:IndexPath) {
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath, selected: false)
        } else {
            self.deselectReusableViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        }
    }
    
    /**
     Scroll to the cell at the provided indexPath. If the cell scroll posiition would not fit without pushing the grid outside of its normal scroll bounds, the position wil be the closest compatible
     - Parameter indexPath: IndexPath of the cell to scroll to
     - Parameter scrollPosition: Position to use when scrolling.
     - Parameter animated: Whether to animate the scroll action
     */
    @objc open func scrollToCellAtIndexPath(_ indexPath: IndexPath, atScrollPosition scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        let convertedPath = self.reverseIndexPathConversion(indexPath)
        var absolutePostion = self.sgCollectionViewLayout.rectForItem(at: convertedPath, atScrollPosition: scrollPosition)
        
        // Adjust offset to not overflow content area based on viewsize
        if self.sgCollectionViewLayout.collectionViewContentSize.height - absolutePostion.origin.y < self.collectionView.frame.size.height {
            absolutePostion.origin.y = self.sgCollectionViewLayout.collectionViewContentSize.height - self.collectionView.frame.size.height
            
            if absolutePostion.origin.y < 0 {
                absolutePostion.origin.y = 0
            }
        }
        
        self.collectionView.setContentOffset(absolutePostion.origin, animated: animated)
    }
    
    /// Manually set the content offset for the gridview
    @objc open func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        
        self.collectionView.setContentOffset(contentOffset, animated: animated)
    }
    
    /// - Returns: The `CGPoint` location for the provided gesture in the gridview context
    @objc open func location(for gestureRecognizer:UIGestureRecognizer) -> CGPoint {

        return gestureRecognizer.location(in: self.collectionView)
    }
    
    
    // MARK: Private Pinch Recognizer
    
    @objc internal func handlePinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        if (recognizer.numberOfTouches != 2) {
            
            return
        }
        
        if (recognizer.scale > 0.35 && recognizer.scale < 5) {
            
            self.sgCollectionViewLayout.zoomScale = recognizer.scale
        }
    }
    
    @objc internal func handleTwoFingerTapGesture(_ recognizer: UITapGestureRecognizer) {
        
        if(self.sgCollectionViewLayout.zoomScale != 1.0) {
            self.sgCollectionViewLayout.zoomScale = 1.0
        }
    }
    
    
    // MARK: - Private conversion Methods
    
    fileprivate func convertCVIndexPathToSGIndexPath(_ indexPath: IndexPath) -> IndexPath {
        let row: Int = indexPath.row / self.sgColumnCount
        let column: Int = indexPath.row % self.sgColumnCount
        
        let convertedPath: IndexPath = IndexPath(forSGRow: row, atColumn: column, inSection: indexPath.section)
        
        return convertedPath
    }
    
    fileprivate func reverseIndexPathConversion(_ indexPath: IndexPath) -> IndexPath {
        let item: Int = indexPath.sgRow * self.sgColumnCount + indexPath.sgColumn
        let revertedPath: IndexPath = IndexPath(item: item, section: indexPath.sgSection)
        
        return revertedPath
    }
    
    fileprivate func reverseIndexPathConversionForIndexPaths(_ indexPaths: [IndexPath]) -> [IndexPath] {
        let convertedPaths = NSMutableArray()
        
        for indexPath in indexPaths {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            convertedPaths.add(convertedPath)
        }
        
        return convertedPaths.copy() as! [IndexPath]
    }
    
    fileprivate func numberOfRowsInSection(_ section: Int) -> Int {
        
        return self.dataSource!.dataGridView(self, numberOfRowsInSection: section)
    }
    
    
    // MARK: - SwiftGridReusableViewDelegate Methods
    
    /// Internal to SwiftGridView, do not use
    open func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didSelectViewAtIndexPath indexPath: IndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath as IndexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: true)
            }
            
            self.delegate?.dataGridView?(self, didSelectSectionHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath as IndexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: true)
            }
            
            self.delegate?.dataGridView?(self, didSelectSectionFooterAtIndexPath: indexPath)
            break
        case SwiftGridElementKindHeader:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didSelectHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindGroupedHeader:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didSelectGroupedHeader: self.groupedColumns[indexPath.sgColumn], at: indexPath.sgColumn)
            break
        case SwiftGridElementKindFooter:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didSelectFooterAtIndexPath: indexPath)
            break
        default:
            break
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didDeselectViewAtIndexPath indexPath: IndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath as IndexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: false)
            }
            
            self.delegate?.dataGridView?(self, didDeselectSectionHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath as IndexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: false)
            }
            
            self.delegate?.dataGridView?(self, didDeselectSectionFooterAtIndexPath: indexPath)
            break
        case SwiftGridElementKindHeader:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didDeselectHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindGroupedHeader:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didDeselectGroupedHeader: self.groupedColumns[indexPath.sgColumn], at: indexPath.sgColumn)
            break
        case SwiftGridElementKindFooter:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didDeselectFooterAtIndexPath: indexPath)
            break
        default:
            break
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didHighlightViewAtIndexPath indexPath: IndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            
            if(self.rowSelectionEnabled) {
                self.toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: true)
            }
            break
        case SwiftGridElementKindSectionFooter:
            
            if(self.rowSelectionEnabled) {
                self.toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: true)
            }
            break
        case SwiftGridElementKindHeader:
            break
        case SwiftGridElementKindGroupedHeader:
            break
        case SwiftGridElementKindFooter:
            break
        default:
            break
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didUnhighlightViewAtIndexPath indexPath: IndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            
            if(self.rowSelectionEnabled) {
                self.toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: false)
            }
            break
        case SwiftGridElementKindSectionFooter:
            
            if(self.rowSelectionEnabled) {
                self.toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: false)
            }
            break
        case SwiftGridElementKindHeader:
            break
        case SwiftGridElementKindGroupedHeader:
            break
        case SwiftGridElementKindFooter:
            break
        default:
            break
        }
    }
    
    fileprivate func toggleSelectedOnReusableViewRowOfKind(_ kind: String, atIndexPath indexPath: IndexPath, selected: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            
            if(selected) {
                self.selectReusableViewOfKind(kind, atIndexPath: sgPath)
            } else {
                self.deselectReusableViewOfKind(kind, atIndexPath: sgPath)
            }
            
            guard let reusableView = self.collectionView.supplementaryView(forElementKind: kind, at: itemPath) as? SwiftGridReusableView
                else {
                    continue
            }
            
            reusableView.selected = selected
        }
    }
    
    fileprivate func selectReusableViewOfKind(_ kind: String, atIndexPath indexPath: IndexPath) {
        switch(kind) {
        case SwiftGridElementKindSectionHeader:
            self.selectedSectionHeaders[indexPath] = true
            break
        case SwiftGridElementKindSectionFooter:
            self.selectedSectionFooters[indexPath] = true
            break
        case SwiftGridElementKindHeader:
            self.selectedHeaders[indexPath] = true
            break
        case SwiftGridElementKindGroupedHeader:
            self.selectedGroupedHeaders[indexPath] = true
            break
        case SwiftGridElementKindFooter:
            self.selectedFooters[indexPath] = true
            break
        default:
            break
        }
    }
    
    fileprivate func deselectReusableViewOfKind(_ kind: String, atIndexPath indexPath: IndexPath) {
        switch(kind) {
        case SwiftGridElementKindSectionHeader:
            self.selectedSectionHeaders.removeObject(forKey: indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            self.selectedSectionFooters.removeObject(forKey: indexPath)
            break
        case SwiftGridElementKindHeader:
            self.selectedHeaders.removeObject(forKey: indexPath)
            break
        case SwiftGridElementKindGroupedHeader:
            self.selectedGroupedHeaders.removeObject(forKey: indexPath)
            break
        case SwiftGridElementKindFooter:
            self.selectedFooters.removeObject(forKey: indexPath)
            break
        default:
            break
        }
    }
    
    fileprivate func toggleHighlightOnReusableViewRowOfKind(_ kind: String, atIndexPath indexPath: IndexPath, highlighted: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            guard let reusableView = self.collectionView.supplementaryView(forElementKind: kind, at: itemPath) as? SwiftGridReusableView
                else {
                    continue
            }
            
            reusableView.highlighted = highlighted
        }
    }
    
    
    // MARK: - SwiftGridLayoutDelegate Methods
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let convertedPath: IndexPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        let colWidth: CGFloat = self.delegate!.dataGridView(self, widthOfColumnAtIndex: convertedPath.sgColumn)
        let rowHeight: CGFloat = self.delegate!.dataGridView(self, heightOfRowAtIndexPath: convertedPath)
        
        return CGSize(width: colWidth, height: rowHeight)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightFor row: Int, at indexPath:IndexPath) -> CGFloat {
        let convertedPath: IndexPath = IndexPath(forSGRow: row, atColumn: 0, inSection: indexPath.section)
        
        return self.delegate!.dataGridView(self, heightOfRowAtIndexPath: convertedPath)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForSupplementaryViewOfKind kind: String, atIndexPath indexPath: IndexPath) -> CGFloat {
        var rowHeight: CGFloat = 0
        
        switch(kind) {
        case SwiftGridElementKindHeader:
            if let delegateHeight = self.delegate?.heightForGridHeaderInDataGridView?(self) {
                if delegateHeight > 0 {
                    rowHeight = delegateHeight
                }
            }
            break
        case SwiftGridElementKindFooter:
            if let delegateHeight = self.delegate?.heightForGridFooterInDataGridView?(self) {
                if(delegateHeight > 0) {
                    rowHeight = delegateHeight
                }
            }
            break
        case SwiftGridElementKindSectionHeader:
            if let delegateHeight = self.delegate?.dataGridView?(self, heightOfHeaderInSection: indexPath.section) {
                if(delegateHeight > 0) {
                    rowHeight = delegateHeight
                }
            }
            break
        case SwiftGridElementKindSectionFooter:
            if let delegateHeight = self.delegate?.dataGridView?(self, heightOfFooterInSection: indexPath.section) {
                if(delegateHeight > 0) {
                    rowHeight = delegateHeight
                }
            }
            break
        case SwiftGridElementKindGroupedHeader:
            if let delegateHeight = self.delegate?.heightForGridHeaderInDataGridView?(self) {
                if(delegateHeight > 0) {
                    rowHeight = delegateHeight
                }
            }
            break
        default:
            rowHeight = 0
            break
        }
        
        return rowHeight
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForSupplementaryViewOfKind kind: String, atIndexPath indexPath: IndexPath) -> CGSize {
        var colWidth: CGFloat = 0.0
        let rowHeight: CGFloat = self.collectionView(collectionView, layout: collectionViewLayout, heightForSupplementaryViewOfKind: kind, atIndexPath: indexPath)
        
        if(indexPath.count != 0 && kind != SwiftGridElementKindGroupedHeader) {
            colWidth = self.delegate!.dataGridView(self, widthOfColumnAtIndex: indexPath.row)
        } else if kind == SwiftGridElementKindGroupedHeader {
            let grouping = self.groupedColumns[indexPath.item]
            
            for column in grouping[0] ... grouping[1] {
                colWidth += self.delegate!.dataGridView(self, widthOfColumnAtIndex: column)
            }
        }
        
        return CGSize(width: colWidth, height: rowHeight)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfRowsInSection sectionIndex: Int) -> Int {
        
        return self.numberOfRowsInSection(sectionIndex)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfFrozenRowsInSection sectionIndex: Int) -> Int {
        
        if let frozenRows = self.dataSource?.dataGridView?(self, numberOfFrozenRowsInSection: sectionIndex) {
            
            return frozenRows
        }
        
        
        return 0
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int {
        
        return self.sgColumnCount
    }
    
    internal func collectionView(_ collectionView: UICollectionView, groupedColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> [[Int]] {
        
        return self.groupedColumns
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfFrozenColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int {
        
        if let frozenCount = self.dataSource?.numberOfFrozenColumnsInDataGridView?(self) {
            
            return frozenCount
        } else {
            
            return 0
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, totalColumnWidthForLayout collectionViewLayout: UICollectionViewLayout) -> CGFloat {
    
        return self.sgColumnWidth
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, widthOfColumnAtIndex columnIndex: Int) -> CGFloat {
        
        return self.delegate!.dataGridView(self, widthOfColumnAtIndex :columnIndex)
    }


    // MARK: - UICollectionView DataSource
    
    /// Internal to SwiftGridView, do not use
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return self.sgSectionCount
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfCells: Int = self.sgColumnCount * self.numberOfRowsInSection(section)
        
        return numberOfCells
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.dataSource!.dataGridView(self, cellAtIndexPath: self.convertCVIndexPathToSGIndexPath(indexPath))
        
        return cell
    }
    
    // TODO: Make this more fail friendly?
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView: SwiftGridReusableView
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        switch(kind) {
        case SwiftGridElementKindSectionHeader:
            reusableView = self.dataSource!.dataGridView!(self, sectionHeaderCellAtIndexPath: convertedPath)
            reusableView.selected = self.selectedSectionHeaders[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindSectionFooter:
            reusableView = self.dataSource!.dataGridView!(self, sectionFooterCellAtIndexPath: convertedPath)
            reusableView.selected = self.selectedSectionFooters[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindHeader:
            reusableView = self.dataSource!.dataGridView!(self, gridHeaderViewForColumn: convertedPath.sgColumn)
            reusableView.selected = self.selectedHeaders[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindGroupedHeader:
            reusableView = self.dataSource!.dataGridView!(self, groupedHeaderViewFor: self.groupedColumns[indexPath.item], at: indexPath.item)
            reusableView.selected = self.selectedGroupedHeaders[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindFooter:
            reusableView = self.dataSource!.dataGridView!(self, gridFooterViewForColumn: convertedPath.sgColumn)
            reusableView.selected = self.selectedFooters[convertedPath] != nil ? true : false
            break
        default:
            reusableView = SwiftGridReusableView.init(frame:CGRect.zero)
            break
        }
        
        reusableView.delegate = self
        reusableView.indexPath = convertedPath
        reusableView.elementKind = kind
        
        return reusableView
    }
    
    
    // MARK: - UICollectionView Delegate
    
    fileprivate func selectRowAtIndexPath(_ indexPath: IndexPath, animated: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            self.collectionView.selectItem(at: itemPath, animated: animated, scrollPosition: UICollectionView.ScrollPosition())
        }
    }
    
    fileprivate func deselectRowAtIndexPath(_ indexPath: IndexPath, animated: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            self.collectionView.deselectItem(at: itemPath, animated: animated)
        }
    }
    
    fileprivate func deselectAllItemsIgnoring(_ indexPath: IndexPath, animated: Bool) {
        for itemPath in self.collectionView.indexPathsForSelectedItems ?? [] {
            if(itemPath.item == indexPath.item) {
                continue
            }
            self.collectionView.deselectItem(at: itemPath, animated: animated)
        }
    }
    
    fileprivate func toggleHighlightOnRowAtIndexPath(_ indexPath: IndexPath, highlighted: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            self.collectionView.cellForItem(at: itemPath)?.isHighlighted = highlighted
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.toggleHighlightOnRowAtIndexPath(convertedPath, highlighted: true)
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.toggleHighlightOnRowAtIndexPath(convertedPath, highlighted: false)
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(!self.allowsMultipleSelection) {
            self.deselectAllItemsIgnoring(indexPath, animated: false)
        }
        
        if(self.rowSelectionEnabled) {
            self.selectRowAtIndexPath(convertedPath, animated: false)
        }
        
        self.delegate?.dataGridView?(self, didSelectCellAtIndexPath: convertedPath)
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.deselectRowAtIndexPath(convertedPath, animated: false)
        }
        
        self.delegate?.dataGridView?(self, didDeselectCellAtIndexPath: convertedPath)
    }
    
}
