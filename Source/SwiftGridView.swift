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


public let SwiftGridElementKindHeader: String = "SwiftGridElementKindHeader"
public let SwiftGridElementKindGroupedHeader: String = "SwiftGridElementKindGroupedHeader"
public let SwiftGridElementKindSectionHeader: String = UICollectionElementKindSectionHeader
public let SwiftGridElementKindFooter: String = "SwiftGridElementKindFooter"
public let SwiftGridElementKindSectionFooter: String = UICollectionElementKindSectionFooter


// MARK: - SwiftGridView Class

/**
 `SwiftGridView` is the primary view class, utilizing a UICollectionView and a custom layout handler.
 */
open class SwiftGridView : UIView, UICollectionViewDataSource, UICollectionViewDelegate, SwiftGridLayoutDelegate, SwiftGridReusableViewDelegate {
    
    // MARK: Init
    
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
        self.sgCollectionView = UICollectionView(frame: self.bounds, collectionViewLayout: sgCollectionViewLayout)
        self.sgCollectionView.dataSource = self // TODO: Separate DataSource/Delegate?
        self.sgCollectionView.delegate = self
        self.sgCollectionView.backgroundColor = self.backgroundColor
        self.sgCollectionView.allowsMultipleSelection = true
        
        self.addSubview(self.sgCollectionView)
    }
    
    
    // MARK: Public Variables
    
    #if TARGET_INTERFACE_BUILDER /// Allows IBOutlets to work properly.
    @IBOutlet open weak var dataSource: AnyObject?
    @IBOutlet open weak var delegate: AnyObject?
    #else
    @objc open weak var dataSource: SwiftGridViewDataSource?
    @objc open weak var delegate: SwiftGridViewDelegate?
    #endif
    
    open var allowsSelection: Bool {
        set(allowsSelection) {
            self.sgCollectionView.allowsSelection = allowsSelection
        }
        get {
            return self.sgCollectionView.allowsSelection
        }
    }
    
    /**
     When enabled, multiple cells can be selected. If row selection is enabled, then multiple rows can be selected.
     */
    open var allowsMultipleSelection: Bool = false
    
    /**
     If row selection is enabled, then entire rows will be selected rather than individual cells. This applies to section headers/footers in addition to rows.
     */
    open var rowSelectionEnabled: Bool = false
    
    open var isDirectionalLockEnabled: Bool {
        set(isDirectionalLockEnabled) {
            self.sgCollectionView.isDirectionalLockEnabled = isDirectionalLockEnabled
        }
        get {
            return self.sgCollectionView.isDirectionalLockEnabled
        }
    }
    
    open var bounces: Bool {
        set(bounces) {
            self.sgCollectionView.bounces = bounces
        }
        get {
            return self.sgCollectionView.bounces
        }
    }
    
    /// Determines whether section headers will stick while scrolling vertically or scroll off screen.
    open var stickySectionHeaders: Bool {
        set(stickySectionHeaders) {
            self.sgCollectionViewLayout.stickySectionHeaders = stickySectionHeaders
        }
        get {
            return self.sgCollectionViewLayout.stickySectionHeaders
        }
    }
    
    open var alwaysBounceVertical: Bool {
        set(alwaysBounceVertical) {
            self.sgCollectionView.alwaysBounceVertical = alwaysBounceVertical
        }
        get {
            return self.sgCollectionView.alwaysBounceVertical
        }
    }
    
    open var alwaysBounceHorizontal: Bool {
        set(alwaysBounceHorizontal) {
            self.sgCollectionView.alwaysBounceHorizontal = alwaysBounceHorizontal
        }
        get {
            return self.sgCollectionView.alwaysBounceHorizontal
        }
    }
    
    /*
     A Boolean value that controls whether the horizontal scroll indicator is visible.
     The default value is true. The indicator is visible while tracking is underway and fades out after tracking.
    */
    open var showsHorizontalScrollIndicator: Bool {
        set(showsHorizontalScrollIndicator) {
            self.sgCollectionView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        }
        get {
            return self.sgCollectionView.showsHorizontalScrollIndicator
        }
    }
    
    /*
     A Boolean value that controls whether the vertical scroll indicator is visible.
     The default value is true. The indicator is visible while tracking is underway and fades out after tracking.
     */
    open var showsVerticalScrollIndicator: Bool {
        set(showsVerticalScrollIndicator) {
            self.sgCollectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        }
        get {
            return self.sgCollectionView.showsVerticalScrollIndicator
        }
    }
    
    /// Pinch to expand increases the size of the columns. Experimental feature.
    open var pinchExpandEnabled: Bool = false {
        didSet {
            if(!self.pinchExpandEnabled) {
                self.sgCollectionView.removeGestureRecognizer(self.sgPinchGestureRecognizer)
                self.sgCollectionView.removeGestureRecognizer(self.sgTwoTapGestureRecognizer)
            } else {
                self.sgCollectionView.addGestureRecognizer(self.sgPinchGestureRecognizer)
                self.sgTwoTapGestureRecognizer.numberOfTouchesRequired = 2
                self.sgCollectionView.addGestureRecognizer(self.sgTwoTapGestureRecognizer)
            }
        }
    }
    
    /// returns YES if user has touched. may not yet have started draggin
    open var isTracking: Bool {
        get {
            return self.sgCollectionView.isTracking
        }
    }
    
    /// returns YES if user has started scrolling. this may require some time and or distance to move to initiate dragging
    open var isDragging: Bool {
        get {
            return self.sgCollectionView.isDragging
        }
    }
    /// returns YES if user isn't dragging (touch up) but scroll view is still moving
    open var isDecelerating: Bool {
        get {
            return self.sgCollectionView.isDecelerating
        }
    }
    
    /// default is YES.
    open var scrollsToTop: Bool {
        set(scrollsToTop) {
            self.sgCollectionView.scrollsToTop = scrollsToTop
        }
        get {
            return self.sgCollectionView.scrollsToTop
        }
    }
    
    @available(iOS 10.0, *)
    open var refreshControl: UIRefreshControl? {
        set(refreshControl) {
            self.sgCollectionView.refreshControl = refreshControl
        }
        get {
            return self.sgCollectionView.refreshControl
        }
    }
    
    
    // MARK: Private Variables
    
    fileprivate var sgCollectionView: UICollectionView!
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
    
    
    // MARK: Layout Subviews
    
    // TODO: Is this how resize should be handled?
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if(self.sgCollectionView.frame != self.bounds) {
            self.sgCollectionView.frame = self.bounds
        }
    }
    
    
    // MARK: Public Methods
    
    open func reloadData() {
        _sgSectionCount = 0
        _sgColumnCount = 0
        _sgColumnWidth = 0
        _groupedColumns = nil
        
        self.selectedHeaders = NSMutableDictionary()
        self.selectedGroupedHeaders = NSMutableDictionary()
        self.selectedSectionHeaders = NSMutableDictionary()
        self.selectedSectionFooters = NSMutableDictionary()
        self.selectedFooters = NSMutableDictionary()
        
        sgCollectionViewLayout.resetCachedParameters()
        
        self.sgCollectionView.reloadData()
    }
    
    open func reloadCellsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool) {
        self.reloadCellsAtIndexPaths(indexPaths, animated: animated, completion: nil)
    }
    
    open func reloadCellsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool, completion: ((Bool) -> Void)?) {
        let convertedPaths = self.reverseIndexPathConversionForIndexPaths(indexPaths)
        
        if(animated) {
            self.sgCollectionView.performBatchUpdates({
                self.sgCollectionView.reloadItems(at: convertedPaths)
                }, completion: { completed in
                    completion?(completed)
            })
        } else {
            self.sgCollectionView.reloadItems(at: convertedPaths)
            completion?(true) // TODO: Fix!
        }
    }
    
    open func indexPathForItem(at point: CGPoint) -> IndexPath? {
        if let cvIndexPath: IndexPath = self.sgCollectionView.indexPathForItem(at: point) {
            let convertedPath: IndexPath = self.convertCVIndexPathToSGIndexPath(cvIndexPath)
            
            return convertedPath
        }
        
        return nil
    }
    
    open func indexPath(for cell: SwiftGridCell) -> IndexPath? {
        if let cvIndexPath: IndexPath = self.sgCollectionView.indexPath(for: cell) {
            let convertedPath: IndexPath = self.convertCVIndexPathToSGIndexPath(cvIndexPath)
            
            return convertedPath
        }
        
        return nil
    }
    
    open func cellForItem(at indexPath: IndexPath) -> SwiftGridCell? {
        let revertedPath: IndexPath = self.reverseIndexPathConversion(indexPath)
        let cell = self.sgCollectionView.cellForItem(at: revertedPath) as? SwiftGridCell
        
        return cell
    }
    
    // FIXME: Doesn't work as intended.
//    public func reloadSupplementaryViewsOfKind(elementKind: String, atIndexPaths indexPaths: [NSIndexPath]) {
//        let convertedPaths = self.reverseIndexPathConversionForIndexPaths(indexPaths)
//        let context = UICollectionViewLayoutInvalidationContext()
//        context.invalidateSupplementaryElementsOfKind(elementKind, atIndexPaths: convertedPaths)
//            
//        self.sgCollectionViewLayout.invalidateLayoutWithContext(context)
//    }
    
    @objc(registerClass:forCellReuseIdentifier:)
    open func register(_ cellClass: Swift.AnyClass?, forCellWithReuseIdentifier identifier: String) {
        self.sgCollectionView.register(cellClass, forCellWithReuseIdentifier:identifier)
    }
    
    open func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        self.sgCollectionView.register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    @objc(registerClass:forSupplementaryViewOfKind:withReuseIdentifier:)
    open func register(_ viewClass: Swift.AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
        self.sgCollectionView.register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
    }
    
    open func register(_ nib: UINib?, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        self.sgCollectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }
    
    open func dequeueReusableCellWithReuseIdentifier(_ identifier: String, forIndexPath indexPath: IndexPath!) -> SwiftGridCell {
        let revertedPath: IndexPath = self.reverseIndexPathConversion(indexPath)
        
        return self.sgCollectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: revertedPath) as! SwiftGridCell
    }
    
    open func dequeueReusableSupplementaryViewOfKind(_ elementKind: String, withReuseIdentifier identifier: String, atColumn column: NSInteger) -> SwiftGridReusableView {
        let revertedPath: IndexPath = IndexPath(item: column, section: 0)
        
        return self.sgCollectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: revertedPath) as! SwiftGridReusableView
    }
    
    open func dequeueReusableSupplementaryViewOfKind(_ elementKind: String, withReuseIdentifier identifier: String, forIndexPath indexPath: IndexPath) -> SwiftGridReusableView {
        let revertedPath: IndexPath = self.reverseIndexPathConversion(indexPath)
        
        return self.sgCollectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: revertedPath) as! SwiftGridReusableView
    }
    
    open func selectCellAtIndexPath(_ indexPath:IndexPath, animated: Bool) {
        if(self.rowSelectionEnabled) {
            self.selectRowAtIndexPath(indexPath, animated: animated)
        } else {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            self.sgCollectionView.selectItem(at: convertedPath, animated: animated, scrollPosition: UICollectionViewScrollPosition())
        }
    }
    
    open func deselectCellAtIndexPath(_ indexPath:IndexPath, animated: Bool) {
        
        if(self.rowSelectionEnabled) {
            self.deselectRowAtIndexPath(indexPath, animated: animated)
        } else {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            self.sgCollectionView.deselectItem(at: convertedPath, animated: animated)
        }
    }
    
    open func selectSectionHeaderAtIndexPath(_ indexPath:IndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath, selected: true)
        } else {
            self.selectReusableViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        }
    }
    
    open func deselectSectionHeaderAtIndexPath(_ indexPath:IndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath, selected: false)
        } else {
            self.deselectReusableViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        }
    }
    
    open func selectSectionFooterAtIndexPath(_ indexPath:IndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath, selected: true)
        } else {
            self.selectReusableViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        }
    }
    
    open func deselectSectionFooterAtIndexPath(_ indexPath:IndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath, selected: false)
        } else {
            self.deselectReusableViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        }
    }
    
    open func scrollToCellAtIndexPath(_ indexPath: IndexPath, atScrollPosition scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
        let convertedPath = self.reverseIndexPathConversion(indexPath)
        let absolutePostion = self.sgCollectionViewLayout.rectForItem(at: convertedPath, atScrollPosition: scrollPosition)
        
        self.sgCollectionView.setContentOffset(absolutePostion.origin, animated: animated)
    }
    
    open func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        
        self.sgCollectionView.setContentOffset(contentOffset, animated: animated)
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
    
    
    // MARK: Private conversion Methods
    
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
    
    
    // MARK: SwiftGridReusableViewDelegate Methods
    
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
            
            guard let reusableView = self.sgCollectionView.supplementaryView(forElementKind: kind, at: itemPath) as? SwiftGridReusableView
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
            guard let reusableView = self.sgCollectionView.supplementaryView(forElementKind: kind, at: itemPath) as? SwiftGridReusableView
                else {
                    continue
            }
            
            reusableView.highlighted = highlighted
        }
    }
    
    
    // MARK: SwiftGridLayoutDelegate Methods
    
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
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForSupplementaryViewOfKind kind: String, atIndexPath indexPath: IndexPath) -> CGSize {
        var colWidth: CGFloat = 0.0
        var rowHeight: CGFloat = 0
        
        if(indexPath.count != 0 && kind != SwiftGridElementKindGroupedHeader) {
            colWidth = self.delegate!.dataGridView(self, widthOfColumnAtIndex: indexPath.row)
        }
        
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
            let grouping = self.groupedColumns[indexPath.item]
            
            for column in grouping[0] ... grouping[1] {
                colWidth += self.delegate!.dataGridView(self, widthOfColumnAtIndex: column)
            }
            
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


    // MARK: UICollectionView DataSource
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return self.sgSectionCount
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfCells: Int = self.sgColumnCount * self.numberOfRowsInSection(section)
        
        return numberOfCells
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.dataSource!.dataGridView(self, cellAtIndexPath: self.convertCVIndexPathToSGIndexPath(indexPath))
        
        return cell
    }
    
    // TODO: Make this more fail friendly?
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
    
    
    // MARK UICollectionView Delegate
    
    fileprivate func selectRowAtIndexPath(_ indexPath: IndexPath, animated: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            self.sgCollectionView.selectItem(at: itemPath, animated: animated, scrollPosition: UICollectionViewScrollPosition())
        }
    }
    
    fileprivate func deselectRowAtIndexPath(_ indexPath: IndexPath, animated: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            self.sgCollectionView.deselectItem(at: itemPath, animated: animated)
        }
    }
    
    fileprivate func deselectAllItemsIgnoring(_ indexPath: IndexPath, animated: Bool) {
        for itemPath in self.sgCollectionView.indexPathsForSelectedItems ?? [] {
            if(itemPath.item == indexPath.item) {
                continue
            }
            self.sgCollectionView.deselectItem(at: itemPath, animated: animated)
        }
    }
    
    fileprivate func toggleHighlightOnRowAtIndexPath(_ indexPath: IndexPath, highlighted: Bool) {
        for columnIndex in 0...self.sgColumnCount - 1 {
            let sgPath = IndexPath.init(forSGRow: indexPath.sgRow, atColumn: columnIndex, inSection: indexPath.sgSection)
            let itemPath = self.reverseIndexPathConversion(sgPath)
            self.sgCollectionView.cellForItem(at: itemPath)?.isHighlighted = highlighted
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.toggleHighlightOnRowAtIndexPath(convertedPath, highlighted: true)
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.toggleHighlightOnRowAtIndexPath(convertedPath, highlighted: false)
        }
    }
    
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
    
    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let convertedPath = self.convertCVIndexPathToSGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.deselectRowAtIndexPath(convertedPath, animated: false)
        }
        
        self.delegate?.dataGridView?(self, didDeselectCellAtIndexPath: convertedPath)
    }
    
}
