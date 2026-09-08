// SwiftGridLayout.swift
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

/**
 `SwiftGridLayout` is the layout used by the `SwiftGridView` to properly layout the UICollectionView as a data grid.
 */
class SwiftGridLayout: UICollectionViewLayout {

    // MARK: - Private vars

    fileprivate weak var _delegate: SwiftGridLayoutDelegate?
    fileprivate var layoutDelegate: SwiftGridLayoutDelegate {
        get {
            if _delegate == nil {
                _delegate = self.collectionView!.delegate as? SwiftGridLayoutDelegate
            }

            return _delegate!
        }
    }

    fileprivate var _sgLayoutSize: CGSize = CGSize.zero
    fileprivate var sgLayoutSize: CGSize {
        get {
            if (_sgLayoutSize.equalTo(CGSize.zero)) {
                let totalWidth: CGFloat = self.layoutDelegate.collectionView(self.collectionView!, totalColumnWidthForLayout: self)
                _sgLayoutSize = CGSize(width: totalWidth, height: 0.0)
                let emptyPath: IndexPath = IndexPath()

                // Add in header height
                _sgLayoutSize.height += self.supplementaryHeight(ofKind: SwiftGridElementKindHeader, at: emptyPath)

                // Add Section Sizes
                for sectionIndex: NSInteger in 0..<self.collectionView!.numberOfSections {
                    _sgLayoutSize.height += self.heightOfSectionAtIndexPath(IndexPath(item: 0, section: sectionIndex))
                }

                // Add in footer height
                _sgLayoutSize.height += self.supplementaryHeight(ofKind: SwiftGridElementKindFooter, at: emptyPath)
            }

            return _sgLayoutSize
        }
    }

    fileprivate var _columnGroupings: [[Int]]?
    fileprivate var columnGroupings: [[Int]] {
        get {
            if (_columnGroupings == nil) {
                _columnGroupings = self.layoutDelegate.collectionView(self.collectionView!, groupedColumnsForLayout: self)
            }

            return _columnGroupings!
        }
    }
    fileprivate var _groupedColumns: [Int]?
    fileprivate var groupedColumns: [Int] {
        get {
            if (_groupedColumns == nil) {
                _groupedColumns = [Int]()

                // TODO: Exception handling?
                for grouping in self.columnGroupings {
                    if grouping.count != 2 {
                        continue  // Invalid grouping.
                    }

                    if grouping[0] > grouping[1] {
                        continue  // Grouping index is wrong order
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
            if (_frozenColumnsCount < 0) {
                _frozenColumnsCount = self.layoutDelegate.collectionView(self.collectionView!, numberOfFrozenColumnsForLayout: self)
            }

            return _frozenColumnsCount
        }
    }

    fileprivate var _frozenRowCounts: [Int] = [Int]()
    fileprivate var frozenRowCounts: [Int] {
        get {
            if (_frozenRowCounts.count == 0) {
                for sectionIndex: NSInteger in 0..<self.collectionView!.numberOfSections {
                    _frozenRowCounts.append(self.layoutDelegate.collectionView(self.collectionView!, layout: self, numberOfFrozenRowsInSection: sectionIndex))
                }
            }

            return _frozenRowCounts
        }
    }

    fileprivate var horizontalOffsetCache: NSMutableDictionary = NSMutableDictionary()
    fileprivate var verticalOffsetCache: NSMutableDictionary = NSMutableDictionary()

    // MARK: - Public Variables

    var stickySectionHeaders: Bool = true

    /// Axis (or axes) affected by `zoomScale`.
    var zoomAxis: SwiftGridZoomAxis = .horizontal {
        didSet {
            if oldValue != zoomAxis && _zoomScale != 1.0 {
                // Re-apply the current zoom against the new axis. The height has
                // to be rebuilt whichever way the axis moved, so this cannot go
                // through the zoomScale setter.
                self.recalculateLayoutSize(recomputingHeight: true)
            }
        }
    }

    fileprivate var _zoomScale: CGFloat = 1.0
    var zoomScale: CGFloat {
        get {

            return _zoomScale
        }
        set(zoomScale) {
            _zoomScale = zoomScale

            self.recalculateLayoutSize(recomputingHeight: self.zoomAxis.scalesVertically)
        }
    }

    // MARK: - Public Methods

    /**
     Rebuilds the cached content size at the current zoom scale and invalidates
     the layout, without discarding the zoom.

     - Parameter recomputingHeight: Whether to rebuild the height from the
       delegate. That walks every row of every section, so it is skipped when
       nothing can have changed a height: a zoom on a purely horizontal axis
       repeats at gesture rate and only ever scales widths.
     */
    func recalculateLayoutSize(recomputingHeight: Bool = true) {
        self.resetCachedParameters(false)

        let totalHeight: CGFloat

        if recomputingHeight || _sgLayoutSize.equalTo(CGSize.zero) {
            // Discard the cached size rather than carry it over: with a vertical
            // axis the height is built from zoom-modified heights.
            _sgLayoutSize = CGSize.zero
            totalHeight = self.sgLayoutSize.height
        } else {
            totalHeight = _sgLayoutSize.height
        }

        let widthScale: CGFloat = self.zoomAxis.scalesHorizontally ? _zoomScale : 1.0
        let totalWidth: CGFloat = self.layoutDelegate.collectionView(self.collectionView!, totalColumnWidthForLayout: self) * widthScale
        _sgLayoutSize = CGSize(width: totalWidth, height: totalHeight)

        self.invalidateLayout()
    }

    func resetCachedParameters(_ resetSize: Bool = true) {  // Rename?
        if (resetSize) {
            _zoomScale = 1.0
            _sgLayoutSize = CGSize.zero
        }

        _columnGroupings = nil
        _groupedColumns = nil
        _frozenColumnsCount = -1
        _frozenRowCounts = [Int]()
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

    override var collectionViewContentSize: CGSize {

        return self.sgLayoutSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesArray: Array<UICollectionViewLayoutAttributes> = []
        let sizeMax = CGSize(width: rect.origin.x + rect.size.width, height: rect.origin.y + rect.size.height)

        // Add in Grid Headers
        // Skip headers when height is 0
        let zeroPath = IndexPath(item: 0, section: 0)

        if (self.supplementaryViewSize(
            ofKind: SwiftGridElementKindHeader, at: zeroPath
        ).height > 0) {
            for attributeIndex: Int in 0..<self.numberOfColumns() {
                let layoutAttributes = self.layoutAttributesForSupplementaryView(
                    ofKind: SwiftGridElementKindHeader, at: IndexPath(item: attributeIndex, section: 0))!

                if (rect.intersects(layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                } else if (layoutAttributes.frame.origin.x > sizeMax.width) {
                    // All future values are not visible.
                    break
                }
            }

            // Add in Grouped Headers
            for attributeIndex: Int in 0..<self.columnGroupings.count {
                let layoutAttributes = self.layoutAttributesForSupplementaryView(
                    ofKind: SwiftGridElementKindGroupedHeader, at: IndexPath(item: attributeIndex, section: 0))!

                if (rect.intersects(layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                } else if (layoutAttributes.frame.origin.x > sizeMax.width) {
                    // All future values are not visible.
                    break
                }
            }
        }

        for sectionIndex: Int in 0..<self.collectionView!.numberOfSections {
            let numberOfItemsInSection: Int = self.numberOfColumns() * self.numberOfRowsInSection(sectionIndex)
            var startItem: Int = 0

            // Add section headers
            // Skip section headers when height is 0
            let sectionPath = IndexPath(item: 0, section: sectionIndex)
            if (self.supplementaryViewSize(
                ofKind: SwiftGridElementKindSectionHeader, at: sectionPath
            ).height > 0) {
                for attributeIndex: Int in 0..<self.numberOfColumns() {
                    let layoutAttributes = self.layoutAttributesForSupplementaryView(
                        ofKind: SwiftGridElementKindSectionHeader, at: IndexPath(item: attributeIndex, section: sectionIndex))!

                    if (rect.intersects(layoutAttributes.frame)) {
                        attributesArray.append(layoutAttributes)
                    } else if (layoutAttributes.frame.origin.x > sizeMax.width) {
                        // All future values are not visible.
                        break
                    }
                }
            }

            // Add frozen row cells
            var frozenRowCount: Int = self.frozenRowCounts[sectionIndex]

            if frozenRowCount > self.numberOfRowsInSection(sectionIndex) {
                frozenRowCount = self.numberOfRowsInSection(sectionIndex)
            }

            // TODO: Possibly refactor?
            if frozenRowCount > 0 {
                let numberOfFrozenItemsInSection: Int = self.numberOfColumns() * frozenRowCount
                startItem = numberOfFrozenItemsInSection
                var attributeIndex = 0

                while attributeIndex < numberOfFrozenItemsInSection {
                    let layoutAttributes = self.layoutAttributesForItem(at: IndexPath(item: attributeIndex, section: sectionIndex))!

                    if (rect.intersects(layoutAttributes.frame)) {
                        attributesArray.append(layoutAttributes)
                        attributeIndex += 1
                    } else if (layoutAttributes.frame.origin.x > sizeMax.width) {
                        // Skip to next row.
                        attributeIndex = (attributeIndex / self.numberOfColumns() + 1) * self.numberOfColumns()
                    } else if (layoutAttributes.frame.origin.y > sizeMax.height) {
                        // All future values are not visible.
                        break
                    } else {
                        attributeIndex += 1
                    }
                }
            }

            // Add row cells
            let attributeStartIndex = self.attributeStartAtOffset(
                self.collectionView!.contentOffset.y, inSection: sectionIndex, withStartItem: startItem, andMaxItems: numberOfItemsInSection)
            var attributeIndex = attributeStartIndex

            while attributeIndex < numberOfItemsInSection {
                let layoutAttributes = self.layoutAttributesForItem(at: IndexPath(item: attributeIndex, section: sectionIndex))!

                if (rect.intersects(layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                    attributeIndex += 1
                } else if (layoutAttributes.frame.origin.x > sizeMax.width) {
                    // Skip to next row.
                    attributeIndex = (attributeIndex / self.numberOfColumns() + 1) * self.numberOfColumns()
                } else if (layoutAttributes.frame.origin.y > sizeMax.height) {
                    // All future values are not visible.
                    break
                } else {
                    attributeIndex += 1
                }
            }

            // Add section footers
            // Skip section footers when height is 0
            if (self.supplementaryViewSize(
                ofKind: SwiftGridElementKindSectionFooter, at: sectionPath
            ).height > 0) {
                for attributeIndex: Int in 0..<self.numberOfColumns() {
                    let layoutAttributes = self.layoutAttributesForSupplementaryView(
                        ofKind: SwiftGridElementKindSectionFooter, at: IndexPath(item: attributeIndex, section: sectionIndex))!

                    if (rect.intersects(layoutAttributes.frame)) {
                        attributesArray.append(layoutAttributes)
                    } else if (layoutAttributes.frame.origin.x > sizeMax.width || layoutAttributes.frame.origin.y > sizeMax.height) {
                        // All future values are not visible.
                        break
                    }
                }
            }
        }

        // Add in Grid Footers
        // Skip footers when height is 0
        if (self.supplementaryViewSize(
            ofKind: SwiftGridElementKindFooter, at: zeroPath
        ).height > 0) {
            for attributeIndex: Int in 0..<self.numberOfColumns() {
                let layoutAttributes = self.layoutAttributesForSupplementaryView(
                    ofKind: SwiftGridElementKindFooter, at: IndexPath(item: attributeIndex, section: 0))!

                if (rect.intersects(layoutAttributes.frame)) {
                    attributesArray.append(layoutAttributes)
                } else if (layoutAttributes.frame.origin.x > sizeMax.width) {
                    // All future values are not visible.
                    break
                }
            }
        }

        return attributesArray
    }

    func rectForItem(at indexPath: IndexPath, atScrollPosition scrollPosition: UICollectionView.ScrollPosition) -> CGRect {
        let currentColumn: Int = indexPath.item % self.numberOfColumns()
        let cellSize: CGSize = self.itemSize(at: indexPath)
        let xOffset: CGFloat = self.horizontalOffset(for: indexPath, atColumn: currentColumn, atScrollPosition: scrollPosition)
        let yOffset: CGFloat = self.verticalOffset(for: indexPath, atScrollPosition: scrollPosition)

        return CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedWidth(cellSize.width), height: cellSize.height)
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        let currentColumn: Int = indexPath.item % self.numberOfColumns()
        let rowNumber: Int = indexPath.item / self.numberOfColumns()
        let cellSize: CGSize = self.itemSize(at: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: currentColumn)
        let yOffset: CGFloat = self.verticalOffsetAtIndexPath(indexPath)

        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedWidth(cellSize.width), height: cellSize.height)

        // Frozen column
        if currentColumn < self.frozenColumnsCount {
            // Frozen row
            if rowNumber < self.frozenRowCounts[indexPath.section] {
                attributes.zIndex = Int.max - currentColumn - 2  // FIXME: Something better?
            } else {
                attributes.zIndex = Int.max - currentColumn - 3  // FIXME: Something better?
            }
        } else if rowNumber < self.frozenRowCounts[indexPath.section] {
            // Frozen row
            attributes.zIndex = indexPath.section + 1  // FIXME: Something better?
        } else {
            attributes.zIndex = indexPath.section
        }

        return attributes
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        var attributes: UICollectionViewLayoutAttributes

        switch (elementKind) {
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
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(
            forSupplementaryViewOfKind: SwiftGridElementKindHeader, with: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = (self.collectionView!.contentOffset.y > 0) ? self.collectionView!.contentOffset.y : 0.0  // Sticky grid header
        var viewSize: CGSize = self.supplementaryViewSize(ofKind: SwiftGridElementKindHeader, at: indexPath)

        // FIXME: Sticky header

        if self.groupedColumns.contains(indexPath.item) {
            // Grouped Column
            viewSize.height = viewSize.height / 2
            yOffset += viewSize.height
        }

        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedWidth(viewSize.width), height: viewSize.height)
        attributes.zIndex = Int.max - indexPath.item  // FIXME: Something better?

        return attributes
    }

    func layoutAttributesForGroupedHeaderAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(
            forSupplementaryViewOfKind: SwiftGridElementKindGroupedHeader, with: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: self.columnGroupings[indexPath.item][0])
        let yOffset: CGFloat = (self.collectionView!.contentOffset.y > 0) ? self.collectionView!.contentOffset.y : 0.0  // Sticky grid header
        var viewSize: CGSize = self.supplementaryViewSize(ofKind: SwiftGridElementKindGroupedHeader, at: indexPath)
        viewSize.height = viewSize.height / 2

        // Adjust Grouping width based on frozen columns
        if self.frozenColumnsCount > 0 && self.frozenColumnsCount > self.columnGroupings[indexPath.item][0]
            && self.frozenColumnsCount <= self.columnGroupings[indexPath.item][1]
        {
            let groupingMin = self.horizontalOffsetAtIndexPath(indexPath, atColumn: self.frozenColumnsCount - 1)
            let groupingMax = self.horizontalOffsetAtIndexPath(indexPath, atColumn: self.columnGroupings[indexPath.item][1])
            let frozenMinWidth = self.layoutDelegate.collectionView(self.collectionView!, layout: self, widthOfColumnAtIndex: self.frozenColumnsCount - 1)
            let frozenMaxWidth = self.layoutDelegate.collectionView(
                self.collectionView!, layout: self, widthOfColumnAtIndex: self.columnGroupings[indexPath.item][1])

            if xOffset + viewSize.width > groupingMax + frozenMaxWidth {
                viewSize.width = groupingMax + frozenMaxWidth - xOffset

                if xOffset + viewSize.width < groupingMin + frozenMinWidth {
                    viewSize.width = groupingMin + frozenMinWidth - xOffset
                }
            }
        }

        // FIXME: Sticky header

        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedWidth(viewSize.width), height: viewSize.height)
        attributes.zIndex = Int.max - self.columnGroupings[indexPath.item][0]  // FIXME: Something better?

        return attributes
    }

    func layoutAttributesForFooterAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(
            forSupplementaryViewOfKind: SwiftGridElementKindFooter, with: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = self.sgLayoutSize.height  // Not sticky footer
        let viewSize: CGSize = self.supplementaryViewSize(ofKind: SwiftGridElementKindFooter, at: indexPath)

        if (self.collectionView!.frame.size.height > self.sgLayoutSize.height) {
            yOffset = self.sgLayoutSize.height
        } else {
            yOffset = self.collectionView!.frame.size.height
        }

        yOffset += self.collectionView!.contentOffset.y  // Sticky footer

        // FIXME: Seems to be off by a pixel at times
        yOffset -= self.supplementaryHeight(ofKind: SwiftGridElementKindFooter, at: indexPath)

        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedWidth(viewSize.width), height: viewSize.height)
        attributes.zIndex = Int.max - indexPath.item  // FIXME: Something better?

        return attributes
    }

    func layoutAttributesForSectionHeaderAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(
            forSupplementaryViewOfKind: SwiftGridElementKindSectionHeader, with: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = 0.0
        let viewSize: CGSize = self.supplementaryViewSize(ofKind: SwiftGridElementKindSectionHeader, at: indexPath)

        // Add in header height
        let headerHeight = self.supplementaryHeight(ofKind: SwiftGridElementKindHeader, at: indexPath)
        yOffset += headerHeight

        for sectionIndex: Int in 0..<indexPath.section {
            let sectionPath = IndexPath(item: 0, section: sectionIndex)
            yOffset += self.heightOfSectionAtIndexPath(sectionPath)
        }

        let contentOffset = self.collectionView!.contentOffset.y + headerHeight
        if (self.stickySectionHeaders && contentOffset > yOffset) {
            let sectionHeight = self.heightOfSectionAtIndexPath(indexPath)

            if (yOffset + sectionHeight - viewSize.height > contentOffset) {
                yOffset = contentOffset
            } else {
                yOffset += sectionHeight - viewSize.height
            }
        }

        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedWidth(viewSize.width), height: viewSize.height)
        attributes.zIndex = Int.max - indexPath.item - 1  // FIXME: Something better?

        return attributes
    }

    func layoutAttributesForSectionFooterAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(
            forSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, with: indexPath)
        let xOffset: CGFloat = self.horizontalOffsetAtIndexPath(indexPath, atColumn: indexPath.item)
        var yOffset: CGFloat = 0.0
        let viewSize: CGSize = self.supplementaryViewSize(ofKind: SwiftGridElementKindSectionFooter, at: indexPath)

        // Add in header height
        yOffset += self.supplementaryHeight(ofKind: SwiftGridElementKindHeader, at: indexPath)

        for sectionIndex: Int in 0...indexPath.section {
            let sectionPath = IndexPath(item: 0, section: sectionIndex)
            yOffset += self.heightOfSectionAtIndexPath(sectionPath)
        }

        // Subtract footer height
        yOffset -= self.supplementaryHeight(ofKind: SwiftGridElementKindSectionFooter, at: indexPath)

        attributes.frame = CGRect(x: xOffset, y: yOffset, width: self.zoomModifiedWidth(viewSize.width), height: viewSize.height)

        attributes.zIndex = Int.max - indexPath.item - 2  // FIXME: Something better?

        return attributes
    }

    // MARK: - Private Methods

    func numberOfColumns() -> Int {

        return self.layoutDelegate.collectionView(self.collectionView!, numberOfColumnsForLayout: self)
    }

    func numberOfRowsInSection(_ sectionIndex: Int) -> Int {

        return self.layoutDelegate.collectionView(self.collectionView!, layout: self, numberOfRowsInSection: sectionIndex)
    }

    func horizontalOffset(for indexPath: IndexPath, atColumn column: Int, atScrollPosition scrollPosition: UICollectionView.ScrollPosition) -> CGFloat {
        var offset: CGFloat = 0.0

        if (column > self.frozenColumnsCount) {
            for columnIndex: Int in self.frozenColumnsCount..<column {
                offset += self.zoomModifiedWidth(self.layoutDelegate.collectionView(self.collectionView!, layout: self, widthOfColumnAtIndex: columnIndex))
            }
        }

        if scrollPosition.contains(.right) {
            offset += self.zoomModifiedWidth(self.layoutDelegate.collectionView(self.collectionView!, layout: self, widthOfColumnAtIndex: column))
        } else if scrollPosition.contains(.centeredHorizontally) {
            offset += self.zoomModifiedWidth(self.layoutDelegate.collectionView(self.collectionView!, layout: self, widthOfColumnAtIndex: column)) / 2
        }

        return offset
    }

    func horizontalOffsetAtIndexPath(_ indexPath: IndexPath, atColumn column: Int) -> CGFloat {
        var offset: CGFloat = 0.0

        // TODO: column as key issues?

        if (self.horizontalOffsetCache[column] != nil) {
            /// Check Cache
            offset = CGFloat((self.horizontalOffsetCache[column] as? NSNumber)!.floatValue)
        } else {
            if (column > 0) {
                offset = self.horizontalOffsetForColumnAtIndex(column)
            }

            self.horizontalOffsetCache[column] = offset
        }

        // Frozen Columns
        if (column < self.frozenColumnsCount) {
            if (self.collectionView!.contentOffset.x > 0) {
                offset += self.collectionView!.contentOffset.x
            }
        }

        return offset
    }

    func horizontalOffsetForColumnAtIndex(_ column: Int) -> CGFloat {
        var offset: CGFloat = 0.0

        for columnIndex: Int in 0..<column {
            offset += self.zoomModifiedWidth(self.layoutDelegate.collectionView(self.collectionView!, layout: self, widthOfColumnAtIndex: columnIndex))
        }

        return offset
    }

    func verticalOffset(for indexPath: IndexPath, atScrollPosition scrollPosition: UICollectionView.ScrollPosition) -> CGFloat {
        var offset: CGFloat = 0.0
        let rowNumber: Int = indexPath.item / self.numberOfColumns()

        // Add in previous section heights
        for sectionIndex: Int in 0..<indexPath.section {
            let sectionPath = IndexPath(item: 0, section: sectionIndex)
            offset += self.heightOfSectionAtIndexPath(sectionPath)
        }

        // Add in current section row heights
        if (indexPath.item > 0) {
            offset += self.rowHeightSumToRow(rowNumber, atIndexPath: indexPath)
        }

        // Frozen Rows
        if self.frozenRowCounts[indexPath.section] > 0 {
            let sumRowNumber = (rowNumber < self.frozenRowCounts[indexPath.section]) ? rowNumber : self.frozenRowCounts[indexPath.section]
            // If the section has frozen rows, subtract from the offset to make sure the row is visible.
            offset -= self.rowHeightSumToRow(sumRowNumber, atIndexPath: indexPath)
        }

        // Adjust for item scroll position
        if scrollPosition.contains(.bottom) {
            offset += self.rowHeight(forRow: rowNumber, at: indexPath)
        } else if scrollPosition.contains(.centeredVertically) {
            offset += self.rowHeight(forRow: rowNumber, at: indexPath) / 2
        }

        return offset
    }

    func verticalOffsetAtIndexPath(_ indexPath: IndexPath) -> CGFloat {
        var offset: CGFloat = 0.0
        let rowNumber: Int = indexPath.item / self.numberOfColumns()

        if (self.verticalOffsetCache[indexPath] != nil) {
            /// Check Cache
            offset = CGFloat((self.verticalOffsetCache[indexPath] as? NSNumber)!.floatValue)
        } else {
            // Add in header height
            offset += self.supplementaryHeight(ofKind: SwiftGridElementKindHeader, at: indexPath)

            // Add in previous section heights
            for sectionIndex: Int in 0..<indexPath.section {
                let sectionPath = IndexPath(item: 0, section: sectionIndex)
                offset += self.heightOfSectionAtIndexPath(sectionPath)
            }

            // Add in section header height
            offset += self.supplementaryHeight(ofKind: SwiftGridElementKindSectionHeader, at: indexPath)

            // Add in current section row heights
            if (indexPath.item > 0) {
                offset += self.rowHeightSumToRow(rowNumber, atIndexPath: indexPath)
            }

            self.verticalOffsetCache[indexPath] = offset
        }

        // Frozen Rows
        if rowNumber < self.frozenRowCounts[indexPath.section] {
            let headerHeight = self.supplementaryHeight(ofKind: SwiftGridElementKindHeader, at: indexPath)
            let sectionHeaderHeight = self.supplementaryHeight(ofKind: SwiftGridElementKindSectionHeader, at: indexPath)
            let rowOffset = self.rowHeightSumToRow(rowNumber, atIndexPath: indexPath)
            let sectionHeaderOffset = self.stickySectionHeaders ? sectionHeaderHeight : 0.0
            /// If sticky headers are disabled, don't offset for their height
            let contentOffset = self.collectionView!.contentOffset.y + headerHeight + sectionHeaderOffset + rowOffset

            if (contentOffset > offset) {
                let sectionPath = IndexPath(item: 0, section: indexPath.section)
                let sectionHeight = self.heightOfSectionAtIndexPath(sectionPath)
                let sectionFooterHeight = self.supplementaryHeight(ofKind: SwiftGridElementKindSectionFooter, at: indexPath)
                let rowHeight = self.itemSize(at: indexPath).height
                var frozenRowIndex = self.frozenRowCounts[indexPath.section]

                if frozenRowIndex > self.numberOfRowsInSection(indexPath.section) {
                    frozenRowIndex = self.numberOfRowsInSection(indexPath.section)
                }

                let maxFrozenRowHeight = offset + sectionHeight - sectionHeaderHeight - sectionFooterHeight - (CGFloat(frozenRowIndex) * rowHeight)

                if (contentOffset > maxFrozenRowHeight) {
                    offset = maxFrozenRowHeight
                } else {
                    offset = contentOffset
                }
            }
        }

        return offset
    }

    // TODO: Refactor?
    func attributeStartAtOffset(_ offset: CGFloat, inSection section: Int, withStartItem startItem: Int, andMaxItems maxItems: Int) -> Int {
        var min: Int = startItem
        var mid: Int
        var max: Int = maxItems

        while (min < max) {
            mid = (min + max) / 2
            let layoutAttributes = self.layoutAttributesForItem(at: IndexPath(item: mid, section: section))!

            if ((offset - layoutAttributes.frame.size.height) > layoutAttributes.frame.origin.y) {
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
        height +=
            self.supplementaryViewSize(
                ofKind: SwiftGridElementKindSectionHeader, at: indexPath
            ).height

        // Add content Row Heights
        height += self.rowHeightSumToRow(rowCount, atIndexPath: indexPath)

        // Add in section footer height
        height +=
            self.supplementaryViewSize(
                ofKind: SwiftGridElementKindSectionFooter, at: indexPath
            ).height

        return height
    }

    func rowHeightSumToRow(_ maxRow: Int, atIndexPath indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 0.0

        for row: Int in 0..<maxRow {
            height += self.rowHeight(forRow: row, at: indexPath)
        }

        return height
    }

    /// Applies the zoom scale to a width, which only scales when the zoom axis
    /// includes the horizontal.
    func zoomModifiedWidth(_ value: CGFloat) -> CGFloat {
        guard self.zoomAxis.scalesHorizontally else {

            return value
        }

        return round(value * self.zoomScale)
    }

    /// Applies the zoom scale to a height, which only scales when the zoom axis
    /// includes the vertical.
    func zoomModifiedHeight(_ value: CGFloat) -> CGFloat {
        guard self.zoomAxis.scalesVertically else {

            return value
        }

        return round(value * self.zoomScale)
    }

    // MARK: - Zoom Modified Delegate Sizing

    // Every height the layout consumes is read through these, so the content
    // size, the cached offsets and the individual attributes all scale together.

    fileprivate func rowHeight(forRow row: Int, at indexPath: IndexPath) -> CGFloat {

        return self.zoomModifiedHeight(self.layoutDelegate.collectionView(self.collectionView!, layout: self, heightFor: row, at: indexPath))
    }

    fileprivate func supplementaryHeight(ofKind kind: String, at indexPath: IndexPath) -> CGFloat {

        return self.zoomModifiedHeight(
            self.layoutDelegate.collectionView(self.collectionView!, layout: self, heightForSupplementaryViewOfKind: kind, atIndexPath: indexPath))
    }

    fileprivate func itemSize(at indexPath: IndexPath) -> CGSize {
        let size = self.layoutDelegate.collectionView(self.collectionView!, layout: self, sizeForItemAtIndexPath: indexPath)

        return CGSize(width: size.width, height: self.zoomModifiedHeight(size.height))
    }

    fileprivate func supplementaryViewSize(ofKind kind: String, at indexPath: IndexPath) -> CGSize {
        let size = self.layoutDelegate.collectionView(self.collectionView!, layout: self, sizeForSupplementaryViewOfKind: kind, atIndexPath: indexPath)

        return CGSize(width: size.width, height: self.zoomModifiedHeight(size.height))
    }
}
