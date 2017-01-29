// SwiftGridLayout.swift
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


// MARK: - SwiftGridLayoutDelegate

/**
 The `SwiftGridLayoutDelegate` is used for retrieving extra required information to properly display and layout the data grid.
 */
@objc protocol SwiftGridLayoutDelegate : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForSupplementaryViewOfKind kind: String, atIndexPath indexPath: IndexPath) -> CGSize
    
    func collectionView(_ collectionView: UICollectionView, numberOfColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int
    
    func collectionView(_ collectionView: UICollectionView, groupedColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> [[Int]]
    
    func collectionView(_ collectionView: UICollectionView, numberOfFrozenColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int
    
    func collectionView(_ collectionView: UICollectionView, totalColumnWidthForLayout collectionViewLayout: UICollectionViewLayout) -> CGFloat
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfRowsInSection sectionIndex: Int) -> Int
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, widthOfColumnAtIndex columnIndex: Int) -> CGFloat
}

/**
 `SwiftGridLayout` is the layout used by the `SwiftGridView` to properly layout the UICollectionView as a data grid.
 */
class SwiftGridLayout : UICollectionViewLayout {
    
    // MARK: - Private vars
    
    fileprivate lazy var delegate: SwiftGridLayoutDelegate = {
        
        return self.collectionView!.delegate as! SwiftGridLayoutDelegate
    }()
    
    fileprivate var _sgLayoutSize: CGSize = CGSize.zero
    fileprivate var sgLayoutSize: CGSize {
        get {
            if(_sgLayoutSize.equalTo(CGSize.zero)) {
                let totalWidth: CGFloat = self.delegate.collectionView(self.collectionView!, totalColumnWidthForLayout: self)
                _sgLayoutSize = CGSize(width: totalWidth, height: 0.0)
                let emptyPath: IndexPath = IndexPath()
                
                // Add in header height
                _sgLayoutSize.height += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: emptyPath).height
                
                // Add Section Sizes
                for sectionIndex: NSInteger in 0 ..< self.collectionView!.numberOfSections {
                    _sgLayoutSize.height += self.heightOfSectionAtIndexPath(IndexPath(item: 0, section: sectionIndex))
                }
                
                // Add in footer height
                _sgLayoutSize.height += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindFooter, atIndexPath: emptyPath).height
            }
            
            return _sgLayoutSize
        }
    }
    
    fileprivate var _columnGroupings: [[Int]]?
    fileprivate var columnGroupings: [[Int]] {
        get {
            if(_columnGroupings == nil) {
                _columnGroupings = self.delegate.collectionView(self.collectionView!, groupedColumnsForLayout: self)
            }
            
            return _columnGroupings!
        }
    }
    fileprivate var _groupedColumns: [Int]?
    fileprivate var groupedColumns: [Int] {
        get {
            if(_groupedColumns == nil) {
                _groupedColumns = [Int]()
                
                // TODO: Exception handling?
                for grouping in self.columnGroupings {
                    if grouping.count != 2 {
                        continue // Invalid grouping.
                    }
                    if grouping[0] > grouping[1] {
                        continue // Grouping index is wrong order
                    }
                    
                    for i in grouping[0]...grouping[1] {
                        _groupedColumns?.append(i)
                    }
                }
            }
            
            return _groupedColumns!
        }
    }
    
    fileprivate var _frozenColumnsCount: Int = -1
    fileprivate var frozenColumnsCount: Int {
        get {
            if(_frozenColumnsCount < 0) {
                _frozenColumnsCount = self.delegate.collectionView(self.collectionView!, numberOfFrozenColumnsForLayout: self)
            }
            
            return _frozenColumnsCount
        }
    }
    
    fileprivate var horizontalOffsetCache: NSMutableDictionary = NSMutableDictionary()
    fileprivate var verticalOffsetCache: NSMutableDictionary = NSMutableDictionary()
    
    
    // MARK: - Public Variables
    
    var stickySectionHeaders: Bool = true
    fileprivate var _zoomScale: CGFloat = 1.0
    var zoomScale: CGFloat {
        get {
            
            return _zoomScale
        }
        set (zoomScale) {
            _zoomScale = zoomScale
            let totalWidth: CGFloat = self.delegate.collectionView(self.collectionView!, totalColumnWidthForLayout: self) * zoomScale
            _sgLayoutSize = CGSize(width: totalWidth, height: self.sgLayoutSize.height)
            
            
            self.resetCachedParameters(false)
            self.invalidateLayout()
        }
    }
    
    
    // MARK: - Public Methods
    
    func resetCachedParameters(_ resetSize:Bool = true) { // Rename?
        if(resetSize) {
            _zoomScale = 1.0
            _sgLayoutSize = CGSize.zero
        }
        _columnGroupings = nil
        _groupedColumns = nil
        _frozenColumnsCount = -1
        horizontalOffsetCache = NSMutableDictionary()
        verticalOffsetCache = NSMutableDictionary()
    }
    
    
    // MARK: - Layout
    
    override func prepare() {
        super.prepare()
        
        // Do Something?
        
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        
        return true
    }
    
    
    // MARK: - Collection View Layout Overrides
    
    override var collectionViewContentSize : CGSize {

        return self.sgLayoutSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesArray: Array<UICollectionViewLayoutAttributes> = []
        let sizeMax = CGSize(width: rect.origin.x + rect.size.width, height: rect.origin.y + rect.size.height)
        
        // Add in Grid Headers
        // Skip headers when height is 0
        let zeroPath = IndexPath(item: 0, section: 0)
        if(self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: zeroPath).height > 0) {
            for attributeIndex:Int in 0 ..< self.numberOfColumns() {
                let layoutAttributes = self.layoutAttributesForSupplementaryView(ofKind: SwiftGridElementKindHeader, at: IndexPath(item: attributeIndex, section: 0))!
                
                if (rect.intersects(layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                } else if(layoutAttributes.frame.origin.x > sizeMax.width) {
                    // All future values are not visible.
                    break
                }
            }
            
            // Add in Grouped Headers
            for attributeIndex:Int in 0 ..< self.columnGroupings.count {
                let layoutAttributes = self.layoutAttributesForSupplementaryView(ofKind: SwiftGridElementKindGroupedHeader, at: IndexPath(item: attributeIndex, section: 0))!
                
                if (rect.intersects(layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                } else if(layoutAttributes.frame.origin.x > sizeMax.width) {
                    // All future values are not visible.
                    break
                }
            }
        }

        for sectionIndex:Int in 0 ..< self.collectionView!.numberOfSections {
            let numberOfItemsInSection: Int = self.numberOfColumns() * self.numberOfRowsInSection(sectionIndex)
            
            // Add section headers
            // Skip section headers when height is 0
            let sectionPath = IndexPath(item: 0, section: sectionIndex)
            if(self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionHeader, atIndexPath: sectionPath).height > 0) {
                for attributeIndex:Int in 0 ..< self.numberOfColumns() {
                    let layoutAttributes = self.layoutAttributesForSupplementaryView(ofKind: SwiftGridElementKindSectionHeader, at: IndexPath(item: attributeIndex, section: sectionIndex))!
                    
                    if (rect.intersects(layoutAttributes.frame)) {
                        attributesArray.append(layoutAttributes)
                    } else if(layoutAttributes.frame.origin.x > sizeMax.width) {
                        // All future values are not visible.
                        break
                    }
                }
            }
            
            // Add row cells
            let attributeStartIndex = self.attributeStartAtOffset(self.collectionView!.contentOffset.y, inSection: sectionIndex, withMaxItems: numberOfItemsInSection)
            var attributeIndex = attributeStartIndex
            
            while attributeIndex < numberOfItemsInSection {
                let layoutAttributes = self.layoutAttributesForItem(at: IndexPath(item: attributeIndex, section: sectionIndex))!
                
                if (rect.intersects(layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                    attributeIndex += 1
                } else if(layoutAttributes.frame.origin.x > sizeMax.width) {
                    // Skip to next row.
                    attributeIndex = (attributeIndex / self.numberOfColumns() + 1) * self.numberOfColumns()
                } else if(layoutAttributes.frame.origin.y > sizeMax.height) {
                    // All future values are not visible.
                    break
                } else {
                    attributeIndex += 1
                }
            }
            
            // Add section footers
            // Skip section footers when height is 0
            if(self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, atIndexPath: sectionPath).height > 0) {
                for attributeIndex:Int in 0 ..< self.numberOfColumns() {
                    let layoutAttributes = self.layoutAttributesForSupplementaryView(ofKind: SwiftGridElementKindSectionFooter, at: IndexPath(item: attributeIndex, section: sectionIndex))!
                    
                    if (rect.intersects(layoutAttributes.frame)) {
                        attributesArray.append(layoutAttributes)
                    } else if(layoutAttributes.frame.origin.x > sizeMax.width || layoutAttributes.frame.origin.y > sizeMax.height) {
                        // All future values are not visible.
                        break
                    }
                }
            }
        }
        
        // Add in Grid Footers
        // Skip footers when height is 0
        if(self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindFooter, atIndexPath: zeroPath).height > 0) {
            for attributeIndex:Int in 0 ..< self.numberOfColumns() {
                let layoutAttributes = self.layoutAttributesForSupplementaryView(ofKind: SwiftGridElementKindFooter, at: IndexPath(item: attributeIndex, section: 0))!
                
                if (rect.intersects(layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                } else if(layoutAttributes.frame.origin.x > sizeMax.width) {
                    // All future values are not visible.
                    break
                }
            }
        }
        
        return attributesArray
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        let currentColumn: Int = indexPath.row % self.numberOfColumns()
        let cellSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForItemAtIndexPath: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: currentColumn)
        let yOffset: CGFloat = self.verticalOffsetAtIndexPath(indexPath)
        
        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedValue(cellSize.width), height: cellSize.height)
        
        // Frozen column
        if(currentColumn < self.frozenColumnsCount) {
            attributes.zIndex = Int.max - currentColumn - 2 // FIXME: Something better?
        } else {
            attributes.zIndex = indexPath.section
        }
        
        return attributes
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        var attributes: UICollectionViewLayoutAttributes
        
        switch(elementKind) {
        case SwiftGridElementKindSectionHeader:
            attributes = self.layoutAttributesForSectionHeaderAtIndexPath(indexPath)
            break
        case SwiftGridElementKindSectionFooter:
            attributes = self.layoutAttributesForSectionFooterAtIndexPath(indexPath)
            break
        case SwiftGridElementKindHeader:
            attributes = self.layoutAttributesForHeaderAtIndexPath(indexPath)
            break
        case SwiftGridElementKindGroupedHeader:
            attributes = self.layoutAttributesForGroupedHeaderAtIndexPath(indexPath)
            break
        case SwiftGridElementKindFooter:
            attributes = self.layoutAttributesForFooterAtIndexPath(indexPath)
            break
        default:
            attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
            break
        }
        
        return attributes
    }
    
    
    // MARK - Private Methods
    
    func layoutAttributesForHeaderAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftGridElementKindHeader, with: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = (self.collectionView!.contentOffset.y > 0) ?  self.collectionView!.contentOffset.y : 0.0 // Sticky grid header
        var viewSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: indexPath)
        
        // FIXME: Sticky header
        
        if self.groupedColumns.contains(indexPath.item) {
            // Grouped Column
            viewSize.height = viewSize.height / 2
            yOffset += viewSize.height
        }
        
        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedValue(viewSize.width), height: viewSize.height)
        attributes.zIndex = Int.max - indexPath.item // FIXME: Something better?
        
        return attributes
    }
    
    func layoutAttributesForGroupedHeaderAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftGridElementKindGroupedHeader, with: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: self.columnGroupings[indexPath.item][0])
        let yOffset: CGFloat = (self.collectionView!.contentOffset.y > 0) ?  self.collectionView!.contentOffset.y : 0.0 // Sticky grid header
        var viewSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindGroupedHeader, atIndexPath: indexPath)
        viewSize.height = viewSize.height / 2
        
        // Adjust Grouping width based on frozen columns
        if self.frozenColumnsCount > 0 && self.frozenColumnsCount > self.columnGroupings[indexPath.item][0] && self.frozenColumnsCount <= self.columnGroupings[indexPath.item][1] {
            let groupingMin = self.horizontalOffsetAtIndexPath(indexPath, atColumn: self.frozenColumnsCount - 1)
            let groupingMax = self.horizontalOffsetAtIndexPath(indexPath, atColumn: self.columnGroupings[indexPath.item][1])
            let frozenMinWidth = self.delegate.collectionView(self.collectionView!, layout: self, widthOfColumnAtIndex: self.frozenColumnsCount - 1)
            let frozenMaxWidth = self.delegate.collectionView(self.collectionView!, layout: self, widthOfColumnAtIndex: self.columnGroupings[indexPath.item][1])
            
            if xOffset + viewSize.width > groupingMax + frozenMaxWidth {
                viewSize.width = groupingMax + frozenMaxWidth - xOffset
                
                if xOffset + viewSize.width < groupingMin + frozenMinWidth {
                    viewSize.width = groupingMin + frozenMinWidth - xOffset
                }
            }
        }
        
        // FIXME: Sticky header
        
        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedValue(viewSize.width), height: viewSize.height)
        attributes.zIndex = Int.max - self.columnGroupings[indexPath.item][0] // FIXME: Something better?
        
        return attributes
    }
    
    func layoutAttributesForFooterAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftGridElementKindFooter, with: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = self.sgLayoutSize.height // Not sticky footer
        let viewSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindFooter, atIndexPath: indexPath)
        
        if(self.collectionView!.frame.size.height > self.sgLayoutSize.height) {
            yOffset = self.sgLayoutSize.height
        } else {
            yOffset = self.collectionView!.frame.size.height
        }
        
        yOffset += self.collectionView!.contentOffset.y // Sticky footer
        
        // FIXME: Seems to be off by a pixel at times
        yOffset -= self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindFooter, atIndexPath: indexPath).height
        
        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedValue(viewSize.width), height: viewSize.height)
        attributes.zIndex = Int.max - indexPath.item // FIXME: Something better?
        
        return attributes
    }
    
    func layoutAttributesForSectionHeaderAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftGridElementKindSectionHeader, with: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = 0.0
        let viewSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        
        // Add in header height
        let headerHeight = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: indexPath).height
        yOffset += headerHeight
        
        for sectionIndex: Int in 0 ..< indexPath.section {
            let sectionPath = IndexPath(item: 0, section: sectionIndex)
            yOffset += self.heightOfSectionAtIndexPath(sectionPath)
        }
        
        let contentOffset = self.collectionView!.contentOffset.y + headerHeight
        if(self.stickySectionHeaders && contentOffset > yOffset) {
            let sectionHeight = self.heightOfSectionAtIndexPath(indexPath)
            
            if(yOffset + sectionHeight - viewSize.height > contentOffset) {
                yOffset = contentOffset
            } else {
                yOffset += sectionHeight - viewSize.height
            }
        }
        
        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedValue(viewSize.width), height: viewSize.height)
        attributes.zIndex = Int.max - indexPath.item - 1 // FIXME: Something better?
        
        return attributes
    }
    
    func layoutAttributesForSectionFooterAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, with: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = 0.0
        let viewSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        
        // Add in header height
        yOffset += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: indexPath).height
        
        for sectionIndex: Int in 0 ... indexPath.section {
            let sectionPath = IndexPath(item: 0, section: sectionIndex)
            yOffset += self.heightOfSectionAtIndexPath(sectionPath)
        }
        
        yOffset -= self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, atIndexPath: indexPath).height // subtract footer height
        
        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedValue(viewSize.width), height: viewSize.height)
        
        attributes.zIndex = Int.max - indexPath.item - 2 // FIXME: Something better?
        
        return attributes
    }
    
    
    // MARK: - Private Methods
    
    func numberOfColumns() -> Int {
    
        return self.delegate.collectionView(self.collectionView!, numberOfColumnsForLayout: self)
    }
    
    func numberOfRowsInSection(_ sectionIndex:Int) -> Int {
        
        return self.delegate.collectionView(self.collectionView!, layout: self, numberOfRowsInSection: sectionIndex)
    }
    
    func horizontalOffsetAtIndexPath(_ indexPath: IndexPath, atColumn column: Int) -> CGFloat {
        var offset: CGFloat = 0.0
        
        // TODO: column as key issues?
        
        // Frozen Columns
        if(column < self.frozenColumnsCount) {
            if(self.horizontalOffsetCache[column] != nil) { /// Check Cache
                offset = CGFloat((self.horizontalOffsetCache[column] as? NSNumber)!.floatValue)
            } else {
                if (indexPath.row > 0) {
                    offset = self.horizontalOffsetForColumnAtIndex(column)
                }
                
                self.horizontalOffsetCache[column] = offset
            }
            
            if(self.collectionView!.contentOffset.x > 0) {
                offset += self.collectionView!.contentOffset.x
            }
        } else {
            // Regular Columns
            if(self.horizontalOffsetCache[column] != nil) { /// Check Cache
                offset = CGFloat((self.horizontalOffsetCache[column] as? NSNumber)!.floatValue)
            } else {
                if (indexPath.row > 0) {
                    offset = self.horizontalOffsetForColumnAtIndex(column)
                }
                
                self.horizontalOffsetCache[column] = offset
            }
        }
        
        return offset
    }
    
    func horizontalOffsetForColumnAtIndex(_ column: Int) -> CGFloat {
        var offset: CGFloat = 0.0
        
        for columnIndex: Int in 0 ..< column {
            offset += self.zoomModifiedValue(self.delegate.collectionView(self.collectionView!, layout: self, widthOfColumnAtIndex: columnIndex))
        }
        
        return offset
    }
    
    func verticalOffsetAtIndexPath(_ indexPath: IndexPath) -> CGFloat {
        var offset: CGFloat = 0.0
        
        if(self.verticalOffsetCache[indexPath] != nil) { /// Check Cache
            offset = CGFloat((self.verticalOffsetCache[indexPath] as? NSNumber)!.floatValue)
        } else {
            // Add in header height
            offset += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: indexPath).height
            
            // Add in previous section heights
            for sectionIndex: Int in 0 ..< indexPath.section {
                let sectionPath = IndexPath(item: 0, section: sectionIndex)
                offset += self.heightOfSectionAtIndexPath(sectionPath)
            }
            
            // Add in section header height
            offset += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionHeader, atIndexPath: indexPath).height
            
            // Add in current section row heights
            if(indexPath.row > 0) {
                let rowNumber: Int = indexPath.row / self.numberOfColumns()
                
                offset += self.rowHeightSumToRow(rowNumber, atIndexPath: indexPath)
            }
            
            self.verticalOffsetCache[indexPath] = offset
        }
        
        return offset
    }
    
    // TODO: Refactor?
    func attributeStartAtOffset(_ offset:CGFloat, inSection section:Int, withMaxItems maxItems:Int) -> Int {
        var min:Int = 0
        var mid:Int
        var max:Int = maxItems
        
        while(min < max) {
            mid = (min + max) / 2
            let layoutAttributes = self.layoutAttributesForItem(at: IndexPath(item: mid, section: section))!
            
            if( (offset - layoutAttributes.frame.size.height) > layoutAttributes.frame.origin.y) {
                min = mid + 1
            } else {
                max = mid - 1
            }
        }
        
        return min
    }
    
    func heightOfSectionAtIndexPath(_ indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 0.0
        let rowCount: Int = self.numberOfRowsInSection(indexPath.section)
        
        // Add in section header height
        height += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionHeader, atIndexPath: indexPath).height
        
        // Add content Row Heights
        height += self.rowHeightSumToRow(rowCount, atIndexPath:indexPath)
        
        // Add in section footer height
        height += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, atIndexPath: indexPath).height
        
        return height
    }
    
    func rowHeightSumToRow(_ maxRow:Int, atIndexPath indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 0.0
        
        for _: Int in 0 ..< maxRow {
            height += self.delegate.collectionView(self.collectionView!, layout: self, sizeForItemAtIndexPath: indexPath).height
        }
        
        return height
    }
    
    func zoomModifiedValue(_ value:CGFloat) -> CGFloat {
        
        return round(value * self.zoomScale)
    }
}
