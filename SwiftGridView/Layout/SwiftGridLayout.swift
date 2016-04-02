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
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForSupplementaryViewOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> CGSize
    
    func collectionView(collectionView: UICollectionView, numberOfColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int
    
    func collectionView(collectionView: UICollectionView, numberOfFrozenColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int
    
    func collectionView(collectionView: UICollectionView, totalColumnWidthForLayout collectionViewLayout: UICollectionViewLayout) -> CGFloat
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfRowsInSection sectionIndex: Int) -> Int
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, widthOfColumnAtIndex columnIndex: Int) -> CGFloat
}

/**
 `SwiftGridLayout` is the layout used by the `SwiftGridView` to properly layout the UICollectionView as a data grid.
 */
class SwiftGridLayout : UICollectionViewLayout {
    
    // MARK: - Private vars
    
    private lazy var delegate: SwiftGridLayoutDelegate = {
        
        return self.collectionView!.delegate as! SwiftGridLayoutDelegate
    }()
    
    private var _sgLayoutSize: CGSize = CGSizeZero
    private var sgLayoutSize: CGSize {
        get {
            if(CGSizeEqualToSize(_sgLayoutSize, CGSizeZero)) {
                let totalWidth: CGFloat = self.delegate.collectionView(self.collectionView!, totalColumnWidthForLayout: self)
                _sgLayoutSize = CGSizeMake(totalWidth, 0.0)
                let emptyPath: NSIndexPath = NSIndexPath()
                
                // Add in header height
                _sgLayoutSize.height += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: emptyPath).height
                
                // Add Section Sizes
                for sectionIndex: NSInteger in 0 ..< self.collectionView!.numberOfSections() {
                    _sgLayoutSize.height += self.heightOfSectionAtIndexPath(NSIndexPath(forItem: 0, inSection: sectionIndex))
                }
                
                // Add in footer height
                _sgLayoutSize.height += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindFooter, atIndexPath: emptyPath).height
            }
            
            return _sgLayoutSize
        }
    }
    
    private var _frozenColumnsCount: Int = -1
    private var frozenColumnsCount: Int {
        get {
            if(_frozenColumnsCount < 0) {
                _frozenColumnsCount = self.delegate.collectionView(self.collectionView!, numberOfFrozenColumnsForLayout: self)
            }
            
            return _frozenColumnsCount
        }
    }
    
    private var horizontalOffsetCache: NSMutableDictionary = NSMutableDictionary()
    private var verticalOffsetCache: NSMutableDictionary = NSMutableDictionary()
    
    
    // MARK: - Public Variables
    
    var stickySectionHeaders: Bool = true
    private var _zoomScale: CGFloat = 1.0
    var zoomScale: CGFloat {
        get {
            
            return _zoomScale
        }
        set (zoomScale) {
            _zoomScale = zoomScale
            let totalWidth: CGFloat = self.delegate.collectionView(self.collectionView!, totalColumnWidthForLayout: self) * zoomScale
            _sgLayoutSize = CGSizeMake(totalWidth, self.sgLayoutSize.height)
            
            
            self.resetCachedParameters(false)
            self.invalidateLayout()
        }
    }
    
    
    // MARK: - Public Methods
    
    func resetCachedParameters(resetSize:Bool = true) { // Rename?
        if(resetSize) {
            _zoomScale = 1.0
            _sgLayoutSize = CGSizeZero
        }
        _frozenColumnsCount = -1
        horizontalOffsetCache = NSMutableDictionary()
        verticalOffsetCache = NSMutableDictionary()
    }
    
    
    // MARK: - Layout
    
    override func prepareLayout() {
        super.prepareLayout()
        
        // Do Something?
        
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        
        return true
    }
    
    
    // MARK: - Collection View Layout Overrides
    
    override func collectionViewContentSize() -> CGSize {

        return self.sgLayoutSize
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesArray: Array<UICollectionViewLayoutAttributes> = []
        let sizeMax = CGSizeMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
        
        // Add in Grid Headers
        // Skip headers when height is 0
        let zeroPath = NSIndexPath(forItem: 0, inSection: 0)
        if(self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: zeroPath).height > 0) {
            for attributeIndex:Int in 0 ..< self.numberOfColumns() {
                let layoutAttributes = self.layoutAttributesForSupplementaryViewOfKind(SwiftGridElementKindHeader, atIndexPath: NSIndexPath(forItem: attributeIndex, inSection: 0))!
                
                if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                } else if(layoutAttributes.frame.origin.x > sizeMax.width) {
                    // All future values are not visible.
                    break;
                }
            }
        }

        for sectionIndex:Int in 0 ..< self.collectionView!.numberOfSections() {
            let numberOfItemsInSection: Int = self.numberOfColumns() * self.numberOfRowsInSection(sectionIndex)
            
            // Add section headers
            // Skip section headers when height is 0
            let sectionPath = NSIndexPath(forItem: 0, inSection: sectionIndex)
            if(self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionHeader, atIndexPath: sectionPath).height > 0) {
                for attributeIndex:Int in 0 ..< self.numberOfColumns() {
                    let layoutAttributes = self.layoutAttributesForSupplementaryViewOfKind(SwiftGridElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: attributeIndex, inSection: sectionIndex))!
                    
                    if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                        attributesArray.append(layoutAttributes)
                    } else if(layoutAttributes.frame.origin.x > sizeMax.width) {
                        // All future values are not visible.
                        break;
                    }
                }
            }
            
            // Add row cells
            let attributeStartIndex = self.attributeStartAtOffset(self.collectionView!.contentOffset.y, inSection: sectionIndex, withMaxItems: numberOfItemsInSection)
            var attributeIndex = attributeStartIndex
            
            while attributeIndex < numberOfItemsInSection {
                let layoutAttributes = self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: attributeIndex, inSection: sectionIndex))!
                
                if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                    attributeIndex += 1
                } else if(layoutAttributes.frame.origin.x > sizeMax.width) {
                    // Skip to next row.
                    attributeIndex = (attributeIndex / self.numberOfColumns() + 1) * self.numberOfColumns()
                } else if(layoutAttributes.frame.origin.y > sizeMax.height) {
                    // All future values are not visible.
                    break;
                } else {
                    attributeIndex += 1
                }
            }
            
            // Add section footers
            // Skip section footers when height is 0
            if(self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, atIndexPath: sectionPath).height > 0) {
                for attributeIndex:Int in 0 ..< self.numberOfColumns() {
                    let layoutAttributes = self.layoutAttributesForSupplementaryViewOfKind(SwiftGridElementKindSectionFooter, atIndexPath: NSIndexPath(forItem: attributeIndex, inSection: sectionIndex))!
                    
                    if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                        attributesArray.append(layoutAttributes)
                    } else if(layoutAttributes.frame.origin.x > sizeMax.width || layoutAttributes.frame.origin.y > sizeMax.height) {
                        // All future values are not visible.
                        break;
                    }
                }
            }
        }
        
        // Add in Grid Footers
        // Skip footers when height is 0
        if(self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindFooter, atIndexPath: zeroPath).height > 0) {
            for attributeIndex:Int in 0 ..< self.numberOfColumns() {
                let layoutAttributes = self.layoutAttributesForSupplementaryViewOfKind(SwiftGridElementKindFooter, atIndexPath: NSIndexPath(forItem: attributeIndex, inSection: 0))!
                
                if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                } else if(layoutAttributes.frame.origin.x > sizeMax.width) {
                    // All future values are not visible.
                    break;
                }
            }
        }
        
        return attributesArray
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        
        let currentColumn: Int = indexPath.row % self.numberOfColumns();
        let cellSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForItemAtIndexPath: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: currentColumn)
        let yOffset: CGFloat = self.verticalOffsetAtIndexPath(indexPath)
        
        attributes.frame = CGRectMake(xOffset, yOffset, self.zoomModifiedValue(cellSize.width), cellSize.height)
        
        // Frozen column
        if(currentColumn < self.frozenColumnsCount) {
            attributes.zIndex = Int.max - currentColumn - 2 // FIXME: Something better?
        } else {
            attributes.zIndex = indexPath.section
        }
        
        return attributes
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
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
        case SwiftGridElementKindFooter:
            attributes = self.layoutAttributesForFooterAtIndexPath(indexPath)
            break
        default:
            attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
            break
        }
        
        return attributes
    }
    
    
    // MARK - Private Methods
    
    func layoutAttributesForHeaderAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftGridElementKindHeader, withIndexPath: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        let yOffset: CGFloat = (self.collectionView!.contentOffset.y > 0) ?  self.collectionView!.contentOffset.y : 0.0 // Sticky grid header
        let viewSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: indexPath)
        
        // FIXME: Sticky header
        
        attributes.frame = CGRectMake(xOffset, yOffset, self.zoomModifiedValue(viewSize.width), viewSize.height)
        attributes.zIndex = Int.max - indexPath.item // FIXME: Something better?
        
        return attributes
    }
    
    func layoutAttributesForFooterAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftGridElementKindFooter, withIndexPath: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = self.sgLayoutSize.height; // Not sticky footer
        let viewSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindFooter, atIndexPath: indexPath)
        
        if(self.collectionView!.frame.size.height > self.sgLayoutSize.height) {
            yOffset = self.sgLayoutSize.height
        } else {
            yOffset = self.collectionView!.frame.size.height
        }
        
        yOffset += self.collectionView!.contentOffset.y; // Sticky footer
        
        // FIXME: Seems to be off by a pixel at times
        yOffset -= self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindFooter, atIndexPath: indexPath).height
        
        attributes.frame = CGRectMake(xOffset, yOffset, self.zoomModifiedValue(viewSize.width), viewSize.height)
        attributes.zIndex = Int.max - indexPath.item // FIXME: Something better?
        
        return attributes
    }
    
    func layoutAttributesForSectionHeaderAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftGridElementKindSectionHeader, withIndexPath: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = 0.0
        let viewSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionHeader, atIndexPath: indexPath)
        
        // Add in header height
        let headerHeight = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: indexPath).height
        yOffset += headerHeight
        
        for sectionIndex: Int in 0 ..< indexPath.section {
            let sectionPath = NSIndexPath(forItem: 0, inSection: sectionIndex)
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
        
        attributes.frame = CGRectMake(xOffset, yOffset, self.zoomModifiedValue(viewSize.width), viewSize.height)
        attributes.zIndex = Int.max - indexPath.item - 1 // FIXME: Something better?
        
        return attributes
    }
    
    func layoutAttributesForSectionFooterAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, withIndexPath: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = 0.0
        let viewSize: CGSize = self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, atIndexPath: indexPath)
        
        // Add in header height
        yOffset += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: indexPath).height
        
        for sectionIndex: Int in 0 ..< indexPath.section {
            let sectionPath = NSIndexPath(forItem: 0, inSection: sectionIndex)
            yOffset += self.heightOfSectionAtIndexPath(sectionPath)
        }
        
        yOffset -= self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, atIndexPath: indexPath).height // subtract footer height
        
        attributes.frame = CGRectMake(xOffset, yOffset, self.zoomModifiedValue(viewSize.width), viewSize.height)
        
        attributes.zIndex = Int.max - indexPath.item - 2 // FIXME: Something better?
        
        return attributes
    }
    
    
    // MARK: - Private Methods
    
    func numberOfColumns() -> Int {
    
        return self.delegate.collectionView(self.collectionView!, numberOfColumnsForLayout: self);
    }
    
    func numberOfRowsInSection(sectionIndex:Int) -> Int {
        
        return self.delegate.collectionView(self.collectionView!, layout: self, numberOfRowsInSection: sectionIndex)
    }
    
    func horizontalOffsetAtIndexPath(indexPath: NSIndexPath, atColumn column: Int) -> CGFloat {
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
    
    func horizontalOffsetForColumnAtIndex(column: Int) -> CGFloat {
        var offset: CGFloat = 0.0
        
        for columnIndex: Int in 0 ..< column {
            offset += self.zoomModifiedValue(self.delegate.collectionView(self.collectionView!, layout: self, widthOfColumnAtIndex: columnIndex))
        }
        
        return offset
    }
    
    func verticalOffsetAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
        var offset: CGFloat = 0.0
        
        if(self.verticalOffsetCache[indexPath] != nil) { /// Check Cache
            offset = CGFloat((self.verticalOffsetCache[indexPath] as? NSNumber)!.floatValue)
        } else {
            // Add in header height
            offset += self.delegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: SwiftGridElementKindHeader, atIndexPath: indexPath).height
            
            // Add in previous section heights
            for sectionIndex: Int in 0 ..< indexPath.section {
                let sectionPath = NSIndexPath(forItem: 0, inSection: sectionIndex)
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
    func attributeStartAtOffset(offset:CGFloat, inSection section:Int, withMaxItems maxItems:Int) -> Int {
        var min:Int = 0;
        var mid:Int;
        var max:Int = maxItems;
        
        while(min < max) {
            mid = (min + max) / 2;
            let layoutAttributes = self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: mid, inSection: section))!
            
            if( (offset - layoutAttributes.frame.size.height) > layoutAttributes.frame.origin.y) {
                min = mid + 1;
            } else {
                max = mid - 1;
            }
        }
        
        return min;
    }
    
    func heightOfSectionAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
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
    
    func rowHeightSumToRow(maxRow:Int, atIndexPath indexPath: NSIndexPath) -> CGFloat {
        var height: CGFloat = 0.0
        
        for _: Int in 0 ..< maxRow {
            height += self.delegate.collectionView(self.collectionView!, layout: self, sizeForItemAtIndexPath: indexPath).height
        }
        
        return height
    }
    
    func zoomModifiedValue(value:CGFloat) -> CGFloat {
        
        return round(value * self.zoomScale)
    }
}