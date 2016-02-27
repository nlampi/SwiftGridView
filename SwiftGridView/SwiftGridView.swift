// SwiftGridView.swift
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

public extension NSIndexPath {
    convenience init(forDGRow row: Int, atColumn column: Int, inSection section: Int) {
        let indexes: [Int] = [section, column, row]
        
        self.init(indexes: indexes, length: indexes.count)
    }
    
    var dgSection: Int { get {
        
            return self.indexAtPosition(0)
        }
    }
    var dgRow: Int { get {
        
            return self.indexAtPosition(2)
        }
    }
    var dgColumn: Int { get {
        
            return self.indexAtPosition(1)
        }
    }
}

public let SwiftGridElementKindHeader: String = "SwiftGridElementKindHeader"
public let SwiftGridElementKindSectionHeader: String = UICollectionElementKindSectionHeader
public let SwiftGridElementKindFooter: String = "SwiftGridElementKindFooter"
public let SwiftGridElementKindSectionFooter: String = UICollectionElementKindSectionFooter


@objc public protocol SwiftGridViewDataSource {
    func numberOfSectionsInDataGridView(dataGridView: SwiftGridView) -> Int
    func numberOfColumnsInDataGridView(dataGridView: SwiftGridView) -> Int
    func dataGridView(dataGridView: SwiftGridView, numberOfRowsInSection section: Int) -> Int
    func dataGridView(dataGridView: SwiftGridView, cellAtIndexPath indexPath: NSIndexPath) -> SwiftGridCell
    optional func numberOfFrozenColumnsInDataGridView(dataGridView: SwiftGridView) -> Int
    
    // Grid Header
    optional func dataGridView(dataGridView: SwiftGridView, gridHeaderViewForColumn column: NSInteger) -> SwiftGridReusableView
    
    // Grid Footer
    optional func dataGridView(dataGridView: SwiftGridView, gridFooterViewForColumn column: NSInteger) -> SwiftGridReusableView
    
    // Section Header
    optional func dataGridView(dataGridView: SwiftGridView, sectionHeaderCellAtIndexPath indexPath: NSIndexPath) -> SwiftGridReusableView
    
    // Section Footer
    optional func dataGridView(dataGridView: SwiftGridView, sectionFooterCellAtIndexPath indexPath: NSIndexPath) -> SwiftGridReusableView
}


@objc public protocol SwiftGridViewDelegate {
    func dataGridView(dataGridView: SwiftGridView, widthOfColumnAtIndex columnIndex: Int) -> CGFloat
    func dataGridView(dataGridView: SwiftGridView, heightOfRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    
    // Grid Header
    optional func heightForGridHeaderInDataGridView(dataGridView: SwiftGridView) -> CGFloat
    optional func dataGridView(dataGridView: SwiftGridView, didSelectHeaderAtIndexPath indexPath: NSIndexPath)
    optional func dataGridView(dataGridView: SwiftGridView, didDeselectHeaderAtIndexPath indexPath: NSIndexPath)
    
    // Grid Footer
    optional func heightForGridFooterInDataGridView(dataGridView: SwiftGridView) -> CGFloat
    optional func dataGridView(dataGridView: SwiftGridView, didSelectFooterAtIndexPath indexPath: NSIndexPath)
    optional func dataGridView(dataGridView: SwiftGridView, didDeselectFooterAtIndexPath indexPath: NSIndexPath)
    
    // Section Header
    optional func dataGridView(dataGridView: SwiftGridView, heightOfHeaderInSection section: Int) -> CGFloat
    optional func dataGridView(dataGridView: SwiftGridView, didSelectSectionHeaderAtIndexPath indexPath: NSIndexPath)
    optional func dataGridView(dataGridView: SwiftGridView, didDeselectSectionHeaderAtIndexPath indexPath: NSIndexPath)
    
    // Section Footer
    optional func dataGridView(dataGridView: SwiftGridView, heightOfFooterInSection section: Int) -> CGFloat
    optional func dataGridView(dataGridView: SwiftGridView, didSelectSectionFooterAtIndexPath indexPath: NSIndexPath)
    optional func dataGridView(dataGridView: SwiftGridView, didDeselectSectionFooterAtIndexPath indexPath: NSIndexPath)
    
    // Cell selection
    optional func dataGridView(dataGridView: SwiftGridView, didSelectCellAtIndexPath indexPath: NSIndexPath)
    optional func dataGridView(dataGridView: SwiftGridView, didDeselectCellAtIndexPath indexPath: NSIndexPath)
}


public class SwiftGridView : UIView, UICollectionViewDataSource, UICollectionViewDelegate, SwiftGridLayoutDelegate, SwiftGridReusableViewDelegate {
    
    // MARK: - Init
    
    // TODO: Subclass UIView? CollectionView? ScrollView? hide init?
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initDefaults()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initDefaults()
    }
    
    private func initDefaults() {
        dgCollectionViewLayout = SwiftGridLayout()
        
        // FIXME: Use constraints!
        self.dgCollectionView = UICollectionView(frame: self.bounds, collectionViewLayout: dgCollectionViewLayout)
        self.dgCollectionView.dataSource = self // TODO: Separate DataSource/Delegate?
        self.dgCollectionView.delegate = self
        self.dgCollectionView.backgroundColor = UIColor.whiteColor()
        self.dgCollectionView.allowsMultipleSelection = true
        
        self.addSubview(self.dgCollectionView)
    }
    
    
    // MARK: - Public Variables
    
    public weak var dataSource: SwiftGridViewDataSource?
    public weak var delegate: SwiftGridViewDelegate?
    
    public var allowsSelection: Bool {
        set(allowsSelection) {
            self.dgCollectionView.allowsSelection = allowsSelection
        }
        get {
            return self.dgCollectionView.allowsSelection
        }
    }
    
    private var _allowsMultipleSelection: Bool = false
    public var allowsMultipleSelection: Bool {
        set(allowsMultipleSelection) {
            _allowsMultipleSelection = allowsMultipleSelection
        }
        get {
            return _allowsMultipleSelection
        }
    }
    
    private var _rowSelectionEnabled: Bool = false
    public var rowSelectionEnabled: Bool {
        set(rowSelectionEnabled) {
            _rowSelectionEnabled = rowSelectionEnabled
        }
        get {
            return _rowSelectionEnabled
        }
    }
    
    public var bounces: Bool {
        set(bounces) {
            self.dgCollectionView.bounces = bounces
        }
        get {
            return self.dgCollectionView.bounces
        }
    }
    
    public var stickySectionHeaders: Bool {
        set(stickySectionHeaders) {
            self.dgCollectionViewLayout.stickySectionHeaders = stickySectionHeaders
        }
        get {
            return self.dgCollectionViewLayout.stickySectionHeaders
        }
    }
    
    public var alwaysBounceVertical: Bool {
        set(alwaysBounceVertical) {
            self.dgCollectionView.alwaysBounceVertical = alwaysBounceVertical
        }
        get {
            return self.dgCollectionView.alwaysBounceVertical
        }
    }
    
    public var alwaysBounceHorizontal: Bool {
        set(alwaysBounceHorizontal) {
            self.dgCollectionView.alwaysBounceHorizontal = alwaysBounceHorizontal
        }
        get {
            return self.dgCollectionView.alwaysBounceHorizontal
        }
    }
    
    public var showsHorizontalScrollIndicator: Bool {
        set(showsHorizontalScrollIndicator) {
            self.dgCollectionView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        }
        get {
            return self.dgCollectionView.showsHorizontalScrollIndicator
        }
    }
    
    public var showsVerticalScrollIndicator: Bool {
        set(showsVerticalScrollIndicator) {
            self.dgCollectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        }
        get {
            return self.dgCollectionView.showsVerticalScrollIndicator
        }
    }
    
    private var _pinchExpandEnabled: Bool = false
    public var pinchExpandEnabled: Bool {
        set(pinchExpandEnabled) {
            if(_pinchExpandEnabled) {
                if(!pinchExpandEnabled) {
                    self.dgCollectionView.removeGestureRecognizer(self.dgPinchGestureRecognizer)
                    self.dgCollectionView.removeGestureRecognizer(self.dgTwoTapGestureRecognizer)
                }
            } else {
                self.dgCollectionView.addGestureRecognizer(self.dgPinchGestureRecognizer)
                self.dgTwoTapGestureRecognizer.numberOfTouchesRequired = 2
                self.dgCollectionView.addGestureRecognizer(self.dgTwoTapGestureRecognizer)
            }
            
            _pinchExpandEnabled = pinchExpandEnabled
        }
        get {
            return _pinchExpandEnabled
        }
    }
    
    
    // MARK: - Private Variables
    
    private var dgCollectionView: UICollectionView!
    private var dgCollectionViewLayout: SwiftGridLayout!
    private lazy var dgPinchGestureRecognizer:UIPinchGestureRecognizer = UIPinchGestureRecognizer.init(target: self, action: Selector("handlePinchGesture:"))
    private lazy var dgTwoTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: Selector("handleTwoFingerTapGesture:"))
    
    private var _dgSectionCount: Int = 0
    private var dgSectionCount: Int {
        get {
            if(_dgSectionCount == 0) {
                _dgSectionCount = self.dataSource!.numberOfSectionsInDataGridView(self)
            }
            
            return _dgSectionCount;
        }
    }
    
    private var _dgColumnCount: Int = 0
    private var dgColumnCount: Int {
        get {
            if(_dgColumnCount == 0) {
                _dgColumnCount = self.dataSource!.numberOfColumnsInDataGridView(self)
            }
            
            return _dgColumnCount;
        }
    }
    
    private var _dgColumnWidth: CGFloat = 0
    private var dgColumnWidth: CGFloat {
        get {
            if(_dgColumnWidth == 0) {
                
                for(var columnIndex = 0; columnIndex < self.dgColumnCount; columnIndex++) {
                    _dgColumnWidth += self.delegate!.dataGridView(self, widthOfColumnAtIndex: columnIndex);
                }
            }
            
            return _dgColumnWidth;
        }
    }
    
    private var selectedHeaders: NSMutableDictionary = NSMutableDictionary()
    private var selectedSectionHeaders: NSMutableDictionary = NSMutableDictionary()
    private var selectedSectionFooters: NSMutableDictionary = NSMutableDictionary()
    private var selectedFooters: NSMutableDictionary = NSMutableDictionary()
    
    
    // MARK: - Layout Subviews
    
    // TODO: Is this how resize should be handled?
    public override func layoutSubviews() {
        if(self.dgCollectionView.frame != self.bounds) {
            self.dgCollectionView.frame = self.bounds
        }
    }
    
    
    // MARK: - Public Methods
    
    public func reloadData() {
        _dgSectionCount = 0
        _dgColumnCount = 0
        _dgColumnWidth = 0
        
        self.selectedHeaders = NSMutableDictionary()
        self.selectedSectionHeaders = NSMutableDictionary()
        self.selectedSectionFooters = NSMutableDictionary()
        self.selectedFooters = NSMutableDictionary()
        
        dgCollectionViewLayout.resetCachedParameters();
        
        self.dgCollectionView.reloadData()
    }
    
    public func reloadCellsAtIndexPaths(indexPaths: [NSIndexPath], animated: Bool) {
        self.reloadCellsAtIndexPaths(indexPaths, animated: animated, completion: nil)
    }
    
    public func reloadCellsAtIndexPaths(indexPaths: [NSIndexPath], animated: Bool, completion: ((Bool) -> Void)?) {
        let convertedPaths = self.reverseIndexPathConversionForIndexPaths(indexPaths)
        
        if(animated) {
            self.dgCollectionView.performBatchUpdates({
                self.dgCollectionView.reloadItemsAtIndexPaths(convertedPaths)
                }, completion: { completed in
                    completion?(completed)
            })
        } else {
            self.dgCollectionView.reloadItemsAtIndexPaths(convertedPaths)
            completion?(true) // TODO: Fix!
        }
        
    }
    
    // Doesn't work as intended.
//    public func reloadSupplementaryViewsOfKind(elementKind: String, atIndexPaths indexPaths: [NSIndexPath]) {
//        let convertedPaths = self.reverseIndexPathConversionForIndexPaths(indexPaths)
//        let context = UICollectionViewLayoutInvalidationContext()
//        context.invalidateSupplementaryElementsOfKind(elementKind, atIndexPaths: convertedPaths)
//            
//        self.dgCollectionViewLayout.invalidateLayoutWithContext(context)
//    }
    
    public func registerClass(cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        self.dgCollectionView.registerClass(cellClass, forCellWithReuseIdentifier:identifier)
    }
    
    public func registerClass(viewClass: AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
        self.dgCollectionView.registerClass(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
    }
    
    public func dequeueReusableCellWithReuseIdentifier(identifier: String, forIndexPath indexPath: NSIndexPath!) -> SwiftGridCell {
        let revertedPath: NSIndexPath = self.reverseIndexPathConversion(indexPath)
        
        return self.dgCollectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: revertedPath) as! SwiftGridCell
    }
    
    public func dequeueReusableSupplementaryViewOfKind(elementKind: String, withReuseIdentifier identifier: String, atColumn column: NSInteger) -> SwiftGridReusableView {
        let revertedPath: NSIndexPath = NSIndexPath(forItem: column, inSection: 0);
        
        return self.dgCollectionView.dequeueReusableSupplementaryViewOfKind(elementKind, withReuseIdentifier: identifier, forIndexPath: revertedPath) as! SwiftGridReusableView
    }
    
    public func dequeueReusableSupplementaryViewOfKind(elementKind: String, withReuseIdentifier identifier: String, forIndexPath indexPath: NSIndexPath) -> SwiftGridReusableView {
        let revertedPath: NSIndexPath = self.reverseIndexPathConversion(indexPath);
        
        return self.dgCollectionView.dequeueReusableSupplementaryViewOfKind(elementKind, withReuseIdentifier: identifier, forIndexPath: revertedPath) as! SwiftGridReusableView
    }
    
    public func selectCellAtIndexPath(indexPath:NSIndexPath, animated: Bool) {
        if(self.rowSelectionEnabled) {
            self.selectRowAtIndexPath(indexPath, animated: animated)
        } else {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            self.dgCollectionView.selectItemAtIndexPath(convertedPath, animated: animated, scrollPosition: UICollectionViewScrollPosition.None)
        }
    }
    
    public func deselectCellAtIndexPath(indexPath:NSIndexPath, animated: Bool) {
        
        if(self.rowSelectionEnabled) {
            self.deselectRowAtIndexPath(indexPath, animated: animated)
        } else {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            self.dgCollectionView.deselectItemAtIndexPath(convertedPath, animated: animated)
        }
    }
    
    public func selectSectionHeaderAtIndexPath(indexPath:NSIndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath, selected: true)
        } else {
            self.selectReusableViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        }
    }
    
    public func deselectSectionHeaderAtIndexPath(indexPath:NSIndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath, selected: false)
        } else {
            self.deselectReusableViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        }
    }
    
    public func selectSectionFooterAtIndexPath(indexPath:NSIndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath, selected: true)
        } else {
            self.selectReusableViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        }
    }
    
    public func deselectSectionFooterAtIndexPath(indexPath:NSIndexPath) {
        
        if(self.rowSelectionEnabled) {
            self.toggleSelectedOnReusableViewRowOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath, selected: false)
        } else {
            self.deselectReusableViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        }
    }
    
    public func scrollToCellAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
        let convertedPath = self.reverseIndexPathConversion(indexPath)
        
        self.dgCollectionView.scrollToItemAtIndexPath(convertedPath, atScrollPosition: scrollPosition, animated: animated)
    }
    
    /*
    SwiftGrid
    - Base Class
        - Pull To Refresh
        - SizeOfCellAtIndexPath?
        - RectForCellAtIndexPath?
        - RectForSectionCellAtIndexPath?
        - ScrollToCellAtIndexPath position
        - Estimated Heights for performance?
        - indexPathsForVisibleCells
        - indexPathsForVisibleSectionCells
        - reloadCellAtIndexPaths withAnim?
    - Header
        - Future: reorder/longpress-drag?
    - Sections
        - Delegate: canExpandSectionAtIndex
        - DataSource: imageForCellExpansion
        - Delegate: expansionImageLeftPaddingForSection
        - Delegate: expansionImageRightPaddingForSection
    - Cell Based
        - Borders on view (bit mask?)
        - Change border color/width
        - Delegate: shouldHightLightCell
        - Delegate: didHighlightCell
        - Delegate: didUnhighlightRow
    - Footer
        - sticky?
        - Delegate: didSelectFooterAtColIndex, sectionIndexPath?
    - Freeze
        - row/col (first n)
        - Delegate: numberOfFrozenRows? how would that work? per section?... could be cool?
    - Sort
        - Sort direction dataType
        - Indicator Image
            - Asc
            - Desc
            - None
        - Delegate: canSortColumn
        - Delegate: sortOnColumn inDirection
        - DataSource: sortIndicatorImageForSortDirection
        - Delegate: didChangeToSortOnColumn inDirection
    */
    
    
    // MARK: - Private Pinch Recognizer
    
    internal func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        if (recognizer.numberOfTouches() != 2) {
            
            return
        }
        
        if (recognizer.scale > 0.35 && recognizer.scale < 5) {
            
            self.dgCollectionViewLayout.zoomScale = recognizer.scale
        }
    }
    
    internal func handleTwoFingerTapGesture(recognizer: UITapGestureRecognizer) {
        
        if(self.dgCollectionViewLayout.zoomScale != 1.0) {
            self.dgCollectionViewLayout.zoomScale = 1.0
        }
    }
    
    
    // MARK: - Private conversion Methods
    
    private func convertCVIndexPathToDGIndexPath(indexPath: NSIndexPath) -> NSIndexPath {
        let row: Int = indexPath.row / self.dgColumnCount
        let column: Int = indexPath.row % self.dgColumnCount
        
        let convertedPath: NSIndexPath = NSIndexPath(forDGRow: row, atColumn: column, inSection: indexPath.section)
        
        return convertedPath
    }
    
    private func reverseIndexPathConversion(indexPath: NSIndexPath) -> NSIndexPath {
        let item: Int = indexPath.dgRow * self.dgColumnCount + indexPath.dgColumn
        let revertedPath: NSIndexPath = NSIndexPath(forItem: item, inSection: indexPath.dgSection)
        
        return revertedPath
    }
    
    private func reverseIndexPathConversionForIndexPaths(indexPaths: [NSIndexPath]) -> [NSIndexPath] {
        let convertedPaths = NSMutableArray()
        
        for indexPath in indexPaths {
            let convertedPath = self.reverseIndexPathConversion(indexPath)
            convertedPaths.addObject(convertedPath)
        }
        
        return convertedPaths.copy() as! [NSIndexPath]
    }
    
    private func numberOfRowsInSection(section: Int) -> Int {
        
        return self.dataSource!.dataGridView(self, numberOfRowsInSection: section)
    }
    
    
    // MARK: - SwiftGridReusableViewDelegate Methods
    
    public func swiftGridReusableView(reusableView: SwiftGridReusableView, didSelectViewAtIndexPath indexPath: NSIndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: true)
            }
            
            self.delegate?.dataGridView?(self, didSelectSectionHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: true)
            }
            
            self.delegate?.dataGridView?(self, didSelectSectionFooterAtIndexPath: indexPath)
            break
        case SwiftGridElementKindHeader:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didSelectHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindFooter:
            self.selectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didSelectFooterAtIndexPath: indexPath)
            break
        default:
            break
        }
    }
    
    public func swiftGridReusableView(reusableView: SwiftGridReusableView, didDeselectViewAtIndexPath indexPath: NSIndexPath) {
        switch(reusableView.elementKind) {
        case SwiftGridElementKindSectionHeader:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: false)
            }
            
            self.delegate?.dataGridView?(self, didDeselectSectionHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: reusableView.indexPath)
            
            if(self.rowSelectionEnabled) {
                self.toggleSelectedOnReusableViewRowOfKind(reusableView.elementKind, atIndexPath: indexPath, selected: false)
            }
            
            self.delegate?.dataGridView?(self, didDeselectSectionFooterAtIndexPath: indexPath)
            break
        case SwiftGridElementKindHeader:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didDeselectHeaderAtIndexPath: indexPath)
            break
        case SwiftGridElementKindFooter:
            self.deselectReusableViewOfKind(reusableView.elementKind, atIndexPath: indexPath)
            
            self.delegate?.dataGridView?(self, didDeselectFooterAtIndexPath: indexPath)
            break
        default:
            break
        }
    }
    
    public func swiftGridReusableView(reusableView: SwiftGridReusableView, didHighlightViewAtIndexPath indexPath: NSIndexPath) {
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
        case SwiftGridElementKindFooter:
            break
        default:
            break
        }
    }
    
    public func swiftGridReusableView(reusableView: SwiftGridReusableView, didUnhighlightViewAtIndexPath indexPath: NSIndexPath) {
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
        case SwiftGridElementKindFooter:
            break
        default:
            break
        }
    }
    
    private func toggleSelectedOnReusableViewRowOfKind(kind: String, atIndexPath indexPath: NSIndexPath, selected: Bool) {
        for columnIndex in 0...self.dgColumnCount - 1 {
            let dgPath = NSIndexPath.init(forDGRow: indexPath.dgRow, atColumn: columnIndex, inSection: indexPath.dgSection)
            let itemPath = self.reverseIndexPathConversion(dgPath)
            
            if(selected) {
                self.selectReusableViewOfKind(kind, atIndexPath: dgPath)
            } else {
                self.deselectReusableViewOfKind(kind, atIndexPath: dgPath)
            }
            
            guard let reusableView = self.dgCollectionView.supplementaryViewForElementKind(kind, atIndexPath: itemPath) as? SwiftGridReusableView
                else {
                    continue;
            }
            
            reusableView.selected = selected
        }
    }
    
    private func selectReusableViewOfKind(kind: String, atIndexPath indexPath: NSIndexPath) {
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
        case SwiftGridElementKindFooter:
            self.selectedFooters[indexPath] = true
            break
        default:
            break
        }
    }
    
    private func deselectReusableViewOfKind(kind: String, atIndexPath indexPath: NSIndexPath) {
        switch(kind) {
        case SwiftGridElementKindSectionHeader:
            self.selectedSectionHeaders.removeObjectForKey(indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            self.selectedSectionFooters.removeObjectForKey(indexPath)
            break
        case SwiftGridElementKindHeader:
            self.selectedHeaders.removeObjectForKey(indexPath)
            break
        case SwiftGridElementKindFooter:
            self.selectedFooters.removeObjectForKey(indexPath)
            break
        default:
            break
        }
    }
    
    private func toggleHighlightOnReusableViewRowOfKind(kind: String, atIndexPath indexPath: NSIndexPath, highlighted: Bool) {
        for columnIndex in 0...self.dgColumnCount - 1 {
            let dgPath = NSIndexPath.init(forDGRow: indexPath.dgRow, atColumn: columnIndex, inSection: indexPath.dgSection)
            let itemPath = self.reverseIndexPathConversion(dgPath)
            guard let reusableView = self.dgCollectionView.supplementaryViewForElementKind(kind, atIndexPath: itemPath) as? SwiftGridReusableView
                else {
                    continue;
            }
            
            reusableView.highlighted = highlighted
        }
    }
    
    
    // MARK: - SwiftGridLayoutDelegate Methods
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let convertedPath: NSIndexPath = self.convertCVIndexPathToDGIndexPath(indexPath)
        let colWidth: CGFloat = self.delegate!.dataGridView(self, widthOfColumnAtIndex: convertedPath.dgColumn)
        let rowHeight: CGFloat = self.delegate!.dataGridView(self, heightOfRowAtIndexPath: convertedPath)
        
        return CGSizeMake(colWidth, rowHeight)
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForSupplementaryViewOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> CGSize {
        var colWidth: CGFloat = 0.0
        var rowHeight: CGFloat = 0
        
        if(indexPath.length != 0) {
            colWidth = self.delegate!.dataGridView(self, widthOfColumnAtIndex: indexPath.row)
        }
        
        switch(kind) {
        case SwiftGridElementKindHeader:
            let delegateHeight = self.delegate?.heightForGridHeaderInDataGridView?(self)
            
            if(delegateHeight > 0) {
                rowHeight = delegateHeight!
            }
            break;
        case SwiftGridElementKindFooter:
            let delegateHeight = self.delegate?.heightForGridFooterInDataGridView?(self)
            
            if(delegateHeight > 0) {
                rowHeight = delegateHeight!
            }
            break;
        case SwiftGridElementKindSectionHeader:
            let delegateHeight = self.delegate?.dataGridView?(self, heightOfHeaderInSection: indexPath.section)
            
            if(delegateHeight > 0) {
                rowHeight = delegateHeight!
            }
            break;
        case SwiftGridElementKindSectionFooter:
            let delegateHeight = self.delegate?.dataGridView?(self, heightOfFooterInSection: indexPath.section)
            
            if(delegateHeight > 0) {
                rowHeight = delegateHeight!
            }
            break;
        default:
            rowHeight = 0
            break;
        }
        
        return CGSizeMake(colWidth, rowHeight)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfRowsInSection sectionIndex: Int) -> Int {
        
        return self.numberOfRowsInSection(sectionIndex)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int {
        
        return self.dgColumnCount
    }
    
    func collectionView(collectionView: UICollectionView, numberOfFrozenColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int {
        
        if let frozenCount = self.dataSource?.numberOfFrozenColumnsInDataGridView?(self) {
            
            return frozenCount
        } else {
            
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, totalColumnWidthForLayout collectionViewLayout: UICollectionViewLayout) -> CGFloat {
    
        return self.dgColumnWidth
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, widthOfColumnAtIndex columnIndex: Int) -> CGFloat {
        
        return self.delegate!.dataGridView(self, widthOfColumnAtIndex :columnIndex)
    }


    // MARK: - UICollectionView DataSource
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return self.dgSectionCount
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfCells: Int = self.dgColumnCount * self.numberOfRowsInSection(section)
        
        return numberOfCells
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = self.dataSource!.dataGridView(self, cellAtIndexPath: self.convertCVIndexPathToDGIndexPath(indexPath))
        
        return cell
    }
    
    // TODO: Make this more fail friendly?
    public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var reusableView: SwiftGridReusableView
        let convertedPath = self.convertCVIndexPathToDGIndexPath(indexPath)
        
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
            reusableView = self.dataSource!.dataGridView!(self, gridHeaderViewForColumn: convertedPath.dgColumn)
            reusableView.selected = self.selectedHeaders[convertedPath] != nil ? true : false
            break
        case SwiftGridElementKindFooter:
            reusableView = self.dataSource!.dataGridView!(self, gridFooterViewForColumn: convertedPath.dgColumn)
            reusableView.selected = self.selectedFooters[convertedPath] != nil ? true : false
            break
        default:
            reusableView = SwiftGridReusableView.init(frame:CGRectZero)
            break
        }
        
        reusableView.delegate = self
        reusableView.indexPath = convertedPath
        reusableView.elementKind = kind
        
        return reusableView
    }
    
    
    // MARK - UICollectionView Delegate
    
    private func selectRowAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        for columnIndex in 0...self.dgColumnCount - 1 {
            let dgPath = NSIndexPath.init(forDGRow: indexPath.dgRow, atColumn: columnIndex, inSection: indexPath.dgSection)
            let itemPath = self.reverseIndexPathConversion(dgPath)
            self.dgCollectionView.selectItemAtIndexPath(itemPath, animated: animated, scrollPosition: UICollectionViewScrollPosition.None)
        }
    }
    
    private func deselectRowAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        for columnIndex in 0...self.dgColumnCount - 1 {
            let dgPath = NSIndexPath.init(forDGRow: indexPath.dgRow, atColumn: columnIndex, inSection: indexPath.dgSection)
            let itemPath = self.reverseIndexPathConversion(dgPath)
            self.dgCollectionView.deselectItemAtIndexPath(itemPath, animated: animated)
        }
    }
    
    private func deselectAllItemsIgnoring(indexPath: NSIndexPath, animated: Bool) {
        for itemPath in self.dgCollectionView.indexPathsForSelectedItems() ?? [] {
            if(itemPath.item == indexPath.item) {
                continue
            }
            self.dgCollectionView.deselectItemAtIndexPath(itemPath, animated: animated)
        }
    }
    
    private func toggleHighlightOnRowAtIndexPath(indexPath: NSIndexPath, highlighted: Bool) {
        for columnIndex in 0...self.dgColumnCount - 1 {
            let dgPath = NSIndexPath.init(forDGRow: indexPath.dgRow, atColumn: columnIndex, inSection: indexPath.dgSection)
            let itemPath = self.reverseIndexPathConversion(dgPath)
            self.dgCollectionView.cellForItemAtIndexPath(itemPath)?.highlighted = highlighted
        }
    }
    
    public func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let convertedPath = self.convertCVIndexPathToDGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.toggleHighlightOnRowAtIndexPath(convertedPath, highlighted: true)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let convertedPath = self.convertCVIndexPathToDGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.toggleHighlightOnRowAtIndexPath(convertedPath, highlighted: false)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let convertedPath = self.convertCVIndexPathToDGIndexPath(indexPath)
        
        if(!self.allowsMultipleSelection) {
            self.deselectAllItemsIgnoring(indexPath, animated: false)
        }
        
        if(self.rowSelectionEnabled) {
            self.selectRowAtIndexPath(convertedPath, animated: false)
        }
        
        self.delegate?.dataGridView?(self, didSelectCellAtIndexPath: convertedPath)
    }
    
    public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let convertedPath = self.convertCVIndexPathToDGIndexPath(indexPath)
        
        if(self.rowSelectionEnabled) {
            self.deselectRowAtIndexPath(convertedPath, animated: false)
        }
        
        self.delegate?.dataGridView?(self, didDeselectCellAtIndexPath: convertedPath)
    }
    
}