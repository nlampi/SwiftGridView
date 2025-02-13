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
        
        initDefaults()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        initDefaults()
    }
    
    fileprivate func initDefaults() {
        sgCollectionViewLayout = SwiftGridLayout()
        
        // FIXME: Use constraints!?
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: sgCollectionViewLayout)
        collectionView.dataSource = self // TODO: Separate DataSource/Delegate?
        collectionView.delegate = self
        collectionView.backgroundColor = backgroundColor
        collectionView.allowsMultipleSelection = true
        
        addSubview(collectionView)
    }
    
    
    // MARK: - Private Properties
    
    fileprivate var sgCollectionViewLayout: SwiftGridLayout!
    fileprivate lazy var sgPinchGestureRecognizer:UIPinchGestureRecognizer = UIPinchGestureRecognizer.init(target: self, action: #selector(SwiftGridView.handlePinchGesture(_:)))
    fileprivate lazy var sgTwoTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(SwiftGridView.handleTwoFingerTapGesture(_:)))
    
    fileprivate var _sgSectionCount: Int = 0
    fileprivate var sgSectionCount: Int {
        get {
            if(_sgSectionCount == 0) {
                _sgSectionCount = dataSource!.numberOfSectionsInDataGridView(self)
            }
            
            return _sgSectionCount
        }
    }
    
    fileprivate var _sgColumnCount: Int = 0
    fileprivate var sgColumnCount: Int {
        get {
            if(_sgColumnCount == 0) {
                _sgColumnCount = dataSource!.numberOfColumnsInDataGridView(self)
            }
            
            return _sgColumnCount
        }
    }
    
    fileprivate var _sgColumnWidth: CGFloat = 0
    fileprivate var sgColumnWidth: CGFloat {
        get {
            if(_sgColumnWidth == 0) {
                
                for columnIndex in 0 ..< sgColumnCount {
                    _sgColumnWidth += delegate!.dataGridView(self, widthOfColumnAtIndex: columnIndex)
                }
            }
            
            return _sgColumnWidth
        }
    }
    
    fileprivate var _groupedColumns: [[Int]]?
    fileprivate var groupedColumns: [[Int]] {
        get {
            if _groupedColumns == nil {
                if let groupedColumns = dataSource?.columnGroupingsForDataGridView?(self) {
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
            collectionView.allowsSelection = allowsSelection
        }
        get {
            return collectionView.allowsSelection
        }
    }
    
    /// When enabled, multiple cells can be selected. If row selection is enabled, then multiple rows can be selected.
    @objc open var allowsMultipleSelection: Bool = false
    
    /// If row selection is enabled, then entire rows will be selected rather than individual cells. This applies to section headers/footers in addition to rows.
    @objc open var rowSelectionEnabled: Bool = false
    
    /// Array of `SwiftGridCell` for all visible cells.
    @objc open var visibleCells: [SwiftGridCell] {
        get {
            let cells = collectionView.visibleCells as! [SwiftGridCell]
            
            return cells
        }
    }
    
    /// Array of `IndexPath` for all visible cells.
    @objc open var indexPathsForVisibleItems: [IndexPath] {
        get {
            var indexPaths = [IndexPath]()
            for indexPath in collectionView.indexPathsForVisibleItems {
                let convertedPath = convertCVIndexPathToSGIndexPath(indexPath)
                indexPaths.append(convertedPath)
            }
            
            return indexPaths
        }
    }
    
    /// Array of `IndexPath` for any selected cells
    @objc open var indexPathsForSelectedItems: [IndexPath] {
        get {
            return (collectionView.indexPathsForSelectedItems ?? []).map { convertCVIndexPathToSGIndexPath($0) }
        }
    }
    
    /// When directional lock is enabled, the grid is only scrollable in one direction at a time (vertically or horizontally)
    @objc open var isDirectionalLockEnabled: Bool {
        set(isDirectionalLockEnabled) {
            collectionView.isDirectionalLockEnabled = isDirectionalLockEnabled
        }
        get {
            return collectionView.isDirectionalLockEnabled
        }
    }
    
    /// Enables bouncing for the gridvies
    @objc open var bounces: Bool {
        set(bounces) {
            collectionView.bounces = bounces
        }
        get {
            return collectionView.bounces
        }
    }
    
    /// Determines whether section headers will stick while scrolling vertically or scroll off screen.
    @objc open var stickySectionHeaders: Bool {
        set(stickySectionHeaders) {
            sgCollectionViewLayout.stickySectionHeaders = stickySectionHeaders
        }
        get {
            return sgCollectionViewLayout.stickySectionHeaders
        }
    }
    
    /// default NO. if YES and bounces is YES, even if content is smaller than bounds, allow drag vertically
    @objc open var alwaysBounceVertical: Bool {
        set(alwaysBounceVertical) {
            collectionView.alwaysBounceVertical = alwaysBounceVertical
        }
        get {
            return collectionView.alwaysBounceVertical
        }
    }
    
    /// default NO. if YES and bounces is YES, even if content is smaller than bounds, allow drag horizontally
    @objc open var alwaysBounceHorizontal: Bool {
        set(alwaysBounceHorizontal) {
            collectionView.alwaysBounceHorizontal = alwaysBounceHorizontal
        }
        get {
            return collectionView.alwaysBounceHorizontal
        }
    }
    
    /**
     A Boolean value that controls whether the horizontal scroll indicator is visible.
     The default value is true. The indicator is visible while tracking is underway and fades out after tracking.
    */
    @objc open var showsHorizontalScrollIndicator: Bool {
        set(showsHorizontalScrollIndicator) {
            collectionView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        }
        get {
            return collectionView.showsHorizontalScrollIndicator
        }
    }
    
    /**
     A Boolean value that controls whether the vertical scroll indicator is visible.
     The default value is true. The indicator is visible while tracking is underway and fades out after tracking.
     */
    @objc open var showsVerticalScrollIndicator: Bool {
        set(showsVerticalScrollIndicator) {
            collectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        }
        get {
            return collectionView.showsVerticalScrollIndicator
        }
    }
    
    /// Pinch to expand increases the size of the columns. Experimental feature.
    @objc open var pinchExpandEnabled: Bool = false {
        didSet {
            if(!pinchExpandEnabled) {
                collectionView.removeGestureRecognizer(sgPinchGestureRecognizer)
                collectionView.removeGestureRecognizer(sgTwoTapGestureRecognizer)
            } else {
                collectionView.addGestureRecognizer(sgPinchGestureRecognizer)
                sgTwoTapGestureRecognizer.numberOfTouchesRequired = 2
                collectionView.addGestureRecognizer(sgTwoTapGestureRecognizer)
            }
        }
    }
    
    /// - Returns: YES if user has touched. may not yet have started draggin
    @objc open var isTracking: Bool {
        get {
            return collectionView.isTracking
        }
    }
    
    /// - Returns: YES if user has started scrolling. this may require some time and or distance to move to initiate dragging
    @objc open var isDragging: Bool {
        get {
            return collectionView.isDragging
        }
    }
    /// - Returns: YES if user isn't dragging (touch up) but scroll view is still moving
    @objc open var isDecelerating: Bool {
        get {
            return collectionView.isDecelerating
        }
    }
    
    /// Whether or not the gridView will automatically scroll to top when the status bar is tapped. Default is YES.
    @objc open var scrollsToTop: Bool {
        set(scrollsToTop) {
            collectionView.scrollsToTop = scrollsToTop
        }
        get {
            return collectionView.scrollsToTop
        }
    }
    
    @available(iOS 10.0, *)
    @objc open var refreshControl: UIRefreshControl? {
        set(refreshControl) {
            collectionView.refreshControl = refreshControl
        }
        get {
            return collectionView.refreshControl
        }
    }
    
    // MARK: - Layout Subviews
    
    // TODO: Is this how resize should be handled?
    @objc open override func layoutSubviews() {
        super.layoutSubviews()
        
        if(collectionView.frame != bounds) {
            collectionView.frame = bounds
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
        
        selectedHeaders = NSMutableDictionary()
        selectedGroupedHeaders = NSMutableDictionary()
        selectedSectionHeaders = NSMutableDictionary()
        selectedSectionFooters = NSMutableDictionary()
        selectedFooters = NSMutableDictionary()
        
        sgCollectionViewLayout.resetCachedParameters(resetSize)
        
        collectionView.reloadData()
        
        // Adjust offset to not overflow content area based on viewsize
        var contentOffset = collectionView.contentOffset
        if sgCollectionViewLayout.collectionViewContentSize.height - contentOffset.y < collectionView.frame.size.height {
            contentOffset.y = sgCollectionViewLayout.collectionViewContentSize.height - collectionView.frame.size.height
            
            if contentOffset.y < 0 {
                contentOffset.y = 0
            }
            
            collectionView.setContentOffset(contentOffset, animated: false)
        }
    }
    
    /**
     Reloads the specified items by their indexPath(s).
     - Parameter indexPaths: Array of `IndexPath` to reload
     - Parameter animated: Whether to animate the change or not
     */
    @objc open func reloadCellsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool) {
        reloadCellsAtIndexPaths(indexPaths, animated: animated, completion: nil)
    }
    
    /**
     Reloads the specified items by their indexPath(s).
     - Parameter indexPaths: Array of `IndexPath` to reload
     - Parameter animated: Whether to animate the change or not
     - Parameter completion: Completion handler executed upon reload
    */
    @objc open func reloadCellsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool, completion: ((Bool) -> Void)?) {
        let convertedPaths = reverseIndexPathConversionForIndexPaths(indexPaths)
        
        if(animated) {
            collectionView.performBatchUpdates({
                collectionView.reloadItems(at: convertedPaths)
                }, completion: { completed in
                    completion?(completed)
            })
        } else {
            collectionView.reloadItems(at: convertedPaths)
            completion?(true) // TODO: Fix!
        }
    }
    
    /**
     Get the item indexPath based on the provided point
     - Parameter point: `CGPoint` to search for
     - Returns: The indexPath for the appropriate item if it exists
     */
    @objc open func indexPathForItem(at point: CGPoint) -> IndexPath? {
        if let cvIndexPath: IndexPath = collectionView.indexPathForItem(at: point) {
            let convertedPath: IndexPath = convertCVIndexPathToSGIndexPath(cvIndexPath)
            
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
        if let cvIndexPath: IndexPath = collectionView.indexPath(for: cell) {
            let convertedPath: IndexPath = convertCVIndexPathToSGIndexPath(cvIndexPath)
            
            return convertedPath
        }
        
        return nil
    }
    
    /**
     Get the selected indexPath(s) for the provided supplementary view kind
     - Parameter kind: View type `SwiftGridViewElementKind...`
     - Returns: Array of `IndexPath` for the selected view(s)
     */
    @objc open func selectedIndexPathsForSupplementaryView(ofElementKind kind: String) -> [IndexPath] {
        let selectedElements: NSDictionary?

        switch kind {
        case SwiftGridElementKindSectionHeader:
            selectedElements = selectedSectionHeaders
        case SwiftGridElementKindSectionFooter:
            selectedElements = selectedSectionFooters
        case SwiftGridElementKindHeader:
            selectedElements = selectedHeaders
        case SwiftGridElementKindGroupedHeader:
            selectedElements = selectedGroupedHeaders
        case SwiftGridElementKindFooter:
            selectedElements = selectedFooters
        default:
            return []
        }

        return selectedElements?.compactMap { ($0.value as? Bool) == true ? $0.key as? IndexPath : nil } ?? []
    }
    
    /**
     Get the cell for the provided indexPath
     - Parameter indexPath: IndexPath to search for.
     - Returns: The `SwiftGridCell` instance for the provided indexPath
     */
    @objc open func cellForItem(at indexPath: IndexPath) -> SwiftGridCell? {
        let revertedPath: IndexPath = reverseIndexPathConversion(indexPath)
        let cell = collectionView.cellForItem(at: revertedPath) as? SwiftGridCell
        
        return cell
    }
    
    /**
     Get the supplementary view for the provided indexPath
     - Parameter kind: View type `SwiftGridViewElementKind...`
     - Parameter indexPath: IndexPath to search for.
     - Returns: The `SwiftGridReusableView` instance for the provided indexPath
     */
    @objc open func supplementaryView(ofElementKind kind: String, at indexPath: IndexPath) -> SwiftGridReusableView? {
        let revertedPath = reverseIndexPathConversion(indexPath)
        
        return collectionView.supplementaryView(forElementKind: kind, at: revertedPath) as? SwiftGridReusableView
    }
    
    // FIXME: Doesn't work as intended.
//    public func reloadSupplementaryViewsOfKind(elementKind: String, atIndexPaths indexPaths: [NSIndexPath]) {
//        let convertedPaths = reverseIndexPathConversionForIndexPaths(indexPaths)
//        let context = UICollectionViewLayoutInvalidationContext()
//        context.invalidateSupplementaryElementsOfKind(elementKind, atIndexPaths: convertedPaths)
//            
//        sgCollectionViewLayout.invalidateLayoutWithContext(context)
//    }
    
    /// Register the provided class for row cell reuse within the `SwiftGridView`
    @objc(registerClass:forCellReuseIdentifier:)
    open func register(_ cellClass: Swift.AnyClass?, forCellWithReuseIdentifier identifier: String) {
        collectionView.register(cellClass, forCellWithReuseIdentifier:identifier)
    }
    
    /// Register the provided nib for row cell reuse within the `SwiftGridView`
    @objc open func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        collectionView.register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    /// Register the provided class for supplementary cell reuse within the `SwiftGridView`
    @objc(registerClass:forSupplementaryViewOfKind:withReuseIdentifier:)
    open func register(_ viewClass: Swift.AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
        collectionView.register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
    }
    
    /// Register the provided class for supplementary cell reuse within the `SwiftGridView`
    @objc open func register(_ nib: UINib?, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }
    
    /// Dequeue Row Cell
    @objc open func dequeueReusableCellWithReuseIdentifier(_ identifier: String, forIndexPath indexPath: IndexPath!) -> SwiftGridCell {
        let revertedPath: IndexPath = reverseIndexPathConversion(indexPath)
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: revertedPath) as! SwiftGridCell
    }
    
    /// Dequeue Supplementary Cell  by column
    @objc open func dequeueReusableSupplementaryViewOfKind(_ elementKind: String, withReuseIdentifier identifier: String, atColumn column: NSInteger) -> SwiftGridReusableView {
        let revertedPath: IndexPath = IndexPath(item: column, section: 0)
        
        return collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: revertedPath) as! SwiftGridReusableView
    }
    
    /// Dequeue Supplementary Cell  by `IndexPath`
    @objc open func dequeueReusableSupplementaryViewOfKind(_ elementKind: String, withReuseIdentifier identifier: String, forIndexPath indexPath: IndexPath) -> SwiftGridReusableView {
        let revertedPath: IndexPath = reverseIndexPathConversion(indexPath)
        
        return collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: revertedPath) as! SwiftGridReusableView
    }
    
    /// Selects the cell at the provided indexPath
    @objc open func selectCellAtIndexPath(_ indexPath:IndexPath, animated: Bool) {
        if(rowSelectionEnabled) {
            selectRowAtIndexPath(indexPath, animated: animated)
        } else {
            let convertedPath = reverseIndexPathConversion(indexPath)
            collectionView.selectItem(at: convertedPath, animated: animated, scrollPosition: UICollectionView.ScrollPosition())
        }
    }
    
    /// Deselects the cell at the provided indexPath
    @objc open func deselectCellAtIndexPath(_ indexPath:IndexPath, animated: Bool) {
        if(rowSelectionEnabled) {
            deselectRowAtIndexPath(indexPath, animated: animated)
        } else {
            let convertedPath = reverseIndexPathConversion(indexPath)
            collectionView.deselectItem(at: convertedPath, animated: animated)
        }
    }
    
    /// Selects the header at the provided indexPath
    @objc open func selectHeaderAtIndexPath(_ indexPath: IndexPath) {
        selectReusableViewOfKind(SwiftGridElementKindHeader, atIndexPath: indexPath)
    }
    
    /// Deselects the header at the provided indexPath
    @objc open func deselectHeaderAtIndexPath(_ indexPath: IndexPath) {
        deselectReusableViewOfKind(SwiftGridElementKindHeader, atIndexPath: indexPath)
    }
    
    /// Select the section header at the provided indexPath
    @objc open func selectSectionHeaderAtIndexPath(_ indexPath:IndexPath) {
        if(rowSelectionEnabled) {
            toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath, selected: true)
        } else {
            selectReusableViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        }
    }
    
    /// Deselect the section header at the provided indexPath
    @objc open func deselectSectionHeaderAtIndexPath(_ indexPath:IndexPath) {
        if(rowSelectionEnabled) {
            toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath, selected: false)
        } else {
            deselectReusableViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        }
    }
    
    /// Select the section footer at the provided indexPath
    @objc open func selectSectionFooterAtIndexPath(_ indexPath:IndexPath) {
        if(rowSelectionEnabled) {
            toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath, selected: true)
        } else {
            selectReusableViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        }
    }
    
    /// Deselect the section footer at the provided indexPath
    @objc open func deselectSectionFooterAtIndexPath(_ indexPath:IndexPath) {
        if(rowSelectionEnabled) {
            toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath, selected: false)
        } else {
            deselectReusableViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        }
    }
    
    /**
     Scroll to the cell at the provided indexPath. If the cell scroll posiition would not fit without pushing the grid outside of its normal scroll bounds, the position wil be the closest compatible
     - Parameter indexPath: IndexPath of the cell to scroll to
     - Parameter scrollPosition: Position to use when scrolling.
     - Parameter animated: Whether to animate the scroll action
     */
    @objc open func scrollToCellAtIndexPath(_ indexPath: IndexPath, atScrollPosition scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        let convertedPath = reverseIndexPathConversion(indexPath)
        var absolutePostion = sgCollectionViewLayout.rectForItem(at: convertedPath, atScrollPosition: scrollPosition)
        
        // Adjust offset to not overflow content area based on viewsize
        if sgCollectionViewLayout.collectionViewContentSize.height - absolutePostion.origin.y < collectionView.frame.size.height {
            absolutePostion.origin.y = sgCollectionViewLayout.collectionViewContentSize.height - collectionView.frame.size.height
            
            if absolutePostion.origin.y < 0 {
                absolutePostion.origin.y = 0
            }
        }
        
        collectionView.setContentOffset(absolutePostion.origin, animated: animated)
    }
    
    /// Manually set the content offset for the gridview
    @objc open func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        
        collectionView.setContentOffset(contentOffset, animated: animated)
    }
    
    /// - Returns: The `CGPoint` location for the provided gesture in the gridview context
    @objc open func location(for gestureRecognizer:UIGestureRecognizer) -> CGPoint {

        return gestureRecognizer.location(in: collectionView)
    }
    
    
    // MARK: Private Pinch Recognizer
    
    @objc internal func handlePinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        if (recognizer.numberOfTouches != 2) {
            
            return
        }
        
        if (recognizer.scale > 0.35 && recognizer.scale < 5) {
            
            sgCollectionViewLayout.zoomScale = recognizer.scale
        }
    }
    
    @objc internal func handleTwoFingerTapGesture(_ recognizer: UITapGestureRecognizer) {
        
        if(sgCollectionViewLayout.zoomScale != 1.0) {
            sgCollectionViewLayout.zoomScale = 1.0
        }
    }
    
    
    // MARK: - Private conversion Methods
    
    fileprivate func convertCVIndexPathToSGIndexPath(_ indexPath: IndexPath) -> IndexPath {
        let row: Int = indexPath.row / sgColumnCount
        let column: Int = indexPath.row % sgColumnCount
        
        let convertedPath: IndexPath = IndexPath(forSGRow: row, atColumn: column, inSection: indexPath.section)
        
        return convertedPath
    }
    
    fileprivate func reverseIndexPathConversion(_ indexPath: IndexPath) -> IndexPath {
        let item: Int = indexPath.sgRow * sgColumnCount + indexPath.sgColumn
        let revertedPath: IndexPath = IndexPath(item: item, section: indexPath.sgSection)
        
        return revertedPath
    }
    
    fileprivate func reverseIndexPathConversionForIndexPaths(_ indexPaths: [IndexPath]) -> [IndexPath] {
        let convertedPaths = NSMutableArray()
        
        for indexPath in indexPaths {
            let convertedPath = reverseIndexPathConversion(indexPath)
            convertedPaths.add(convertedPath)
        }
        
        return convertedPaths.copy() as! [IndexPath]
    }
    
    fileprivate func numberOfRowsInSection(_ section: Int) -> Int {
        
        return dataSource!.dataGridView(self, numberOfRowsInSection: section)
    }
    
    
    // MARK: - SwiftGridReusableViewDelegate Methods
    
    /// Internal to SwiftGridView, do not use
    open func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didSelectViewAtIndexPath indexPath: IndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            selectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath as IndexPath)
            
            if(rowSelectionEnabled) {
                toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: true)
            }
            
            delegate?.dataGridView?(self, didSelectSectionHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            selectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath as IndexPath)
            
            if(rowSelectionEnabled) {
                toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: true)
            }
            
            delegate?.dataGridView?(self, didSelectSectionFooterAtIndexPath: indexPath)
            break
        case SwiftGridElementKindHeader:
            selectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            delegate?.dataGridView?(self, didSelectHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindGroupedHeader:
            selectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            delegate?.dataGridView?(self, didSelectGroupedHeader: groupedColumns[indexPath.sgColumn], at: indexPath.sgColumn)
            break
        case SwiftGridElementKindFooter:
            selectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            delegate?.dataGridView?(self, didSelectFooterAtIndexPath: indexPath)
            break
        default:
            break
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didDeselectViewAtIndexPath indexPath: IndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath as IndexPath)
            
            if(rowSelectionEnabled) {
                toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: false)
            }
            
            delegate?.dataGridView?(self, didDeselectSectionHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath as IndexPath)
            
            if(rowSelectionEnabled) {
                toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: false)
            }
            
            delegate?.dataGridView?(self, didDeselectSectionFooterAtIndexPath: indexPath)
            break
        case SwiftGridElementKindHeader:
            deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            delegate?.dataGridView?(self, didDeselectHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindGroupedHeader:
            deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            delegate?.dataGridView?(self, didDeselectGroupedHeader: groupedColumns[indexPath.sgColumn], at: indexPath.sgColumn)
            break
        case SwiftGridElementKindFooter:
            deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            delegate?.dataGridView?(self, didDeselectFooterAtIndexPath: indexPath)
            break
        default:
            break
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func swiftGridReusableView(_ reusableView: SwiftGridReusableView, didHighlightViewAtIndexPath indexPath: IndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            
            if(rowSelectionEnabled) {
                toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: true)
            }
            break
        case SwiftGridElementKindSectionFooter:
            
            if(rowSelectionEnabled) {
                toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: true)
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
            
            if(rowSelectionEnabled) {
                toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: false)
            }
            break
        case SwiftGridElementKindSectionFooter:
            
            if(rowSelectionEnabled) {
                toggleHighlightOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, highlighted: false)
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
        for columnIndex in 0...sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = reverseIndexPathConversion(sgPath)
            
            if(selected) {
                selectReusableViewOfKind(kind, atIndexPath: sgPath)
            } else {
                deselectReusableViewOfKind(kind, atIndexPath: sgPath)
            }
            
            guard let reusableView = collectionView.supplementaryView(forElementKind: kind, at: itemPath) as? SwiftGridReusableView
                else {
                    continue
            }
            
            reusableView.selected = selected
        }
    }
    
    fileprivate func selectReusableViewOfKind(_ kind: String, atIndexPath indexPath: IndexPath) {
        switch(kind) {
        case SwiftGridElementKindSectionHeader:
            selectedSectionHeaders[indexPath] = true
            break
        case SwiftGridElementKindSectionFooter:
            selectedSectionFooters[indexPath] = true
            break
        case SwiftGridElementKindHeader:
            selectedHeaders[indexPath] = true
            break
        case SwiftGridElementKindGroupedHeader:
            selectedGroupedHeaders[indexPath] = true
            break
        case SwiftGridElementKindFooter:
            selectedFooters[indexPath] = true
            break
        default:
            break
        }
    }
    
    fileprivate func deselectReusableViewOfKind(_ kind: String, atIndexPath indexPath: IndexPath) {
        switch(kind) {
        case SwiftGridElementKindSectionHeader:
            selectedSectionHeaders.removeObject(forKey: indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            selectedSectionFooters.removeObject(forKey: indexPath)
            break
        case SwiftGridElementKindHeader:
            selectedHeaders.removeObject(forKey: indexPath)
            break
        case SwiftGridElementKindGroupedHeader:
            selectedGroupedHeaders.removeObject(forKey: indexPath)
            break
        case SwiftGridElementKindFooter:
            selectedFooters.removeObject(forKey: indexPath)
            break
        default:
            break
        }
    }
    
    fileprivate func toggleHighlightOnReusableViewRowOfKind(_ kind: String, atIndexPath indexPath: IndexPath, highlighted: Bool) {
        for columnIndex in 0...sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = reverseIndexPathConversion(sgPath)
            guard let reusableView = collectionView.supplementaryView(forElementKind: kind, at: itemPath) as? SwiftGridReusableView
                else {
                    continue
            }
            
            reusableView.highlighted = highlighted
        }
    }
    
    
    // MARK: - SwiftGridLayoutDelegate Methods
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let convertedPath: IndexPath = convertCVIndexPathToSGIndexPath(indexPath)
        let colWidth: CGFloat = delegate!.dataGridView(self, widthOfColumnAtIndex: convertedPath.sgColumn)
        let rowHeight: CGFloat = delegate!.dataGridView(self, heightOfRowAtIndexPath: convertedPath)
        
        return CGSize(width: colWidth, height: rowHeight)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightFor row: Int, at indexPath:IndexPath) -> CGFloat {
        let convertedPath: IndexPath = IndexPath(forSGRow: row, atColumn: 0, inSection: indexPath.section)
        
        return delegate!.dataGridView(self, heightOfRowAtIndexPath: convertedPath)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForSupplementaryViewOfKind kind: String, atIndexPath indexPath: IndexPath) -> CGFloat {
        var rowHeight: CGFloat = 0
        
        switch(kind) {
        case SwiftGridElementKindHeader:
            if let delegateHeight = delegate?.heightForGridHeaderInDataGridView?(self) {
                if delegateHeight > 0 {
                    rowHeight = delegateHeight
                }
            }
            break
        case SwiftGridElementKindFooter:
            if let delegateHeight = delegate?.heightForGridFooterInDataGridView?(self) {
                if(delegateHeight > 0) {
                    rowHeight = delegateHeight
                }
            }
            break
        case SwiftGridElementKindSectionHeader:
            if let delegateHeight = delegate?.dataGridView?(self, heightOfHeaderInSection: indexPath.section) {
                if(delegateHeight > 0) {
                    rowHeight = delegateHeight
                }
            }
            break
        case SwiftGridElementKindSectionFooter:
            if let delegateHeight = delegate?.dataGridView?(self, heightOfFooterInSection: indexPath.section) {
                if(delegateHeight > 0) {
                    rowHeight = delegateHeight
                }
            }
            break
        case SwiftGridElementKindGroupedHeader:
            if let delegateHeight = delegate?.heightForGridHeaderInDataGridView?(self) {
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
            colWidth = delegate!.dataGridView(self, widthOfColumnAtIndex: indexPath.row)
        } else if kind == SwiftGridElementKindGroupedHeader {
            let grouping = groupedColumns[indexPath.item]
            
            for column in grouping[0] ... grouping[1] {
                colWidth += delegate!.dataGridView(self, widthOfColumnAtIndex: column)
            }
        }
        
        return CGSize(width: colWidth, height: rowHeight)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfRowsInSection sectionIndex: Int) -> Int {
        
        return numberOfRowsInSection(sectionIndex)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfFrozenRowsInSection sectionIndex: Int) -> Int {
        
        if let frozenRows = dataSource?.dataGridView?(self, numberOfFrozenRowsInSection: sectionIndex) {
            
            return frozenRows
        }
        
        
        return 0
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int {
        
        return sgColumnCount
    }
    
    internal func collectionView(_ collectionView: UICollectionView, groupedColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> [[Int]] {
        
        return groupedColumns
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfFrozenColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int {
        
        if let frozenCount = dataSource?.numberOfFrozenColumnsInDataGridView?(self) {
            
            return frozenCount
        } else {
            
            return 0
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, totalColumnWidthForLayout collectionViewLayout: UICollectionViewLayout) -> CGFloat {
    
        return sgColumnWidth
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, widthOfColumnAtIndex columnIndex: Int) -> CGFloat {
        
        return delegate!.dataGridView(self, widthOfColumnAtIndex :columnIndex)
    }


    // MARK: - UICollectionView DataSource
    
    /// Internal to SwiftGridView, do not use
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return sgSectionCount
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfCells: Int = sgColumnCount * numberOfRowsInSection(section)
        
        return numberOfCells
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dataSource!.dataGridView(self, cellAtIndexPath: convertCVIndexPathToSGIndexPath(indexPath))
        
        return cell
    }
    
    // TODO: Make this more fail friendly?
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView: SwiftGridReusableView
        let convertedPath = convertCVIndexPathToSGIndexPath(indexPath)
        
        switch(kind) {
        case SwiftGridElementKindSectionHeader:
            reusableView = dataSource!.dataGridView!(self, sectionHeaderCellAtIndexPath: convertedPath)
            reusableView.selected = selectedSectionHeaders[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindSectionFooter:
            reusableView = dataSource!.dataGridView!(self, sectionFooterCellAtIndexPath: convertedPath)
            reusableView.selected = selectedSectionFooters[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindHeader:
            reusableView = dataSource!.dataGridView!(self, gridHeaderViewForColumn: convertedPath.sgColumn)
            reusableView.selected = selectedHeaders[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindGroupedHeader:
            reusableView = dataSource!.dataGridView!(self, groupedHeaderViewFor: groupedColumns[indexPath.item], at: indexPath.item)
            reusableView.selected = selectedGroupedHeaders[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindFooter:
            reusableView = dataSource!.dataGridView!(self, gridFooterViewForColumn: convertedPath.sgColumn)
            reusableView.selected = selectedFooters[convertedPath] != nil ? true : false
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
    
    open func selectColumnAtIndexPath(_ indexPath: IndexPath, animated: Bool, includeHeader: Bool = true) {
        guard indexPath.sgRow >= 0,
              indexPath.sgRow < numberOfRowsInSection(indexPath.sgSection) else {
            return
        }
        
        if includeHeader {
            selectHeaderAtIndexPath(indexPath)
        }
        
        for rowIndex in 0...(numberOfRowsInSection(indexPath.sgSection) - 1) {
            let sgPath = IndexPath.init(forSGRow: rowIndex, atColumn: indexPath.sgColumn, inSection: indexPath.sgSection)
            let itemPath = reverseIndexPathConversion(sgPath)
            collectionView.selectItem(at: itemPath, animated: animated, scrollPosition: UICollectionView.ScrollPosition())
        }
    }
    
    open func deselectColumnAtIndexPath(_ indexPath: IndexPath, animated: Bool, includeHeader: Bool = true) {
        guard indexPath.sgRow >= 0,
              indexPath.sgRow < numberOfRowsInSection(indexPath.sgSection) else {
            return
        }
        
        if includeHeader {
            deselectHeaderAtIndexPath(indexPath)
        }
        
        for rowIndex in 0...(numberOfRowsInSection(indexPath.sgSection) - 1) {
            let sgPath = IndexPath.init(forSGRow: rowIndex, atColumn: indexPath.sgColumn, inSection: indexPath.sgSection)
            let itemPath = reverseIndexPathConversion(sgPath)
            collectionView.deselectItem(at: itemPath, animated: animated)
        }
    }
    
    open func selectRowAtIndexPath(_ indexPath: IndexPath, animated: Bool) {
        guard indexPath.sgRow >= 0,
              indexPath.sgRow < numberOfRowsInSection(indexPath.sgSection) else {
            return
        }
        
        for columnIndex in 0...sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = reverseIndexPathConversion(sgPath)
            collectionView.selectItem(at: itemPath, animated: animated, scrollPosition: UICollectionView.ScrollPosition())
        }
    }
    
    open func deselectRowAtIndexPath(_ indexPath: IndexPath, animated: Bool) {
        guard indexPath.sgRow >= 0,
              indexPath.sgRow < numberOfRowsInSection(indexPath.sgSection) else {
            return
        }
        
        for columnIndex in 0...sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = reverseIndexPathConversion(sgPath)
            collectionView.deselectItem(at: itemPath, animated: animated)
        }
    }
    
    fileprivate func deselectAllItemsIgnoring(_ indexPath: IndexPath, animated: Bool) {
        for itemPath in collectionView.indexPathsForSelectedItems ?? [] {
            if(itemPath.item == indexPath.item) {
                continue
            }
            collectionView.deselectItem(at: itemPath, animated: animated)
        }
    }
    
    fileprivate func toggleHighlightOnRowAtIndexPath(_ indexPath: IndexPath, highlighted: Bool) {
        for columnIndex in 0...sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = reverseIndexPathConversion(sgPath)
            collectionView.cellForItem(at: itemPath)?.isHighlighted = highlighted
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let convertedPath = convertCVIndexPathToSGIndexPath(indexPath)
        
        if(rowSelectionEnabled) {
            toggleHighlightOnRowAtIndexPath(convertedPath, highlighted: true)
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let convertedPath = convertCVIndexPathToSGIndexPath(indexPath)
        
        if(rowSelectionEnabled) {
            toggleHighlightOnRowAtIndexPath(convertedPath, highlighted: false)
        }
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let convertedPath = convertCVIndexPathToSGIndexPath(indexPath)
        
        if(!allowsMultipleSelection) {
            deselectAllItemsIgnoring(indexPath, animated: false)
        }
        
        if(rowSelectionEnabled) {
            selectRowAtIndexPath(convertedPath, animated: false)
        }
        
        delegate?.dataGridView?(self, didSelectCellAtIndexPath: convertedPath)
    }
    
    /// Internal to SwiftGridView, do not use
    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let convertedPath = convertCVIndexPathToSGIndexPath(indexPath)
        
        if(rowSelectionEnabled) {
            deselectRowAtIndexPath(convertedPath, animated: false)
        }
        
        delegate?.dataGridView?(self, didDeselectCellAtIndexPath: convertedPath)
    }
    
}
