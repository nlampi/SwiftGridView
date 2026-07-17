// SwiftGridViewFeatureTests.swift
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

import Testing
import UIKit

@testable import SwiftGridView

// MARK: - Feature Layout

/// Exercises the layout's feature surface: grid and section headers/footers,
/// frozen rows and columns, and grouped headers.
@MainActor
@Suite struct SwiftGridViewFeatureTests {

    private struct Fixture {
        let grid: SwiftGridView
        let dataSource: SGMockFeatureRichDataSource
        let delegate: SGMockFeatureRichDelegate

        var layout: UICollectionViewLayout { grid.collectionView.collectionViewLayout }
        var contentSize: CGSize { layout.collectionViewContentSize }
    }

    private func makeGrid(groupings: [[Int]] = []) -> Fixture {
        let grid = SwiftGridView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let dataSource = SGMockFeatureRichDataSource()
        let delegate = SGMockFeatureRichDelegate()
        dataSource.columnGroupings = groupings
        grid.dataSource = dataSource
        grid.delegate = delegate

        grid.register(SwiftGridTestCell.self, forCellWithReuseIdentifier: SwiftGridTestCell.reuseIdentifier())
        for kind in [
            SwiftGridElementKindHeader, SwiftGridElementKindFooter, SwiftGridElementKindGroupedHeader,
            SwiftGridElementKindSectionHeader, SwiftGridElementKindSectionFooter,
        ] {
            grid.register(SwiftGridReusableView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: SwiftGridReusableView.reuseIdentifier())
        }

        grid.reloadData()
        grid.layoutIfNeeded()

        return Fixture(grid: grid, dataSource: dataSource, delegate: delegate)
    }

    private func attributes(in fixture: Fixture, rect: CGRect? = nil) -> [UICollectionViewLayoutAttributes] {
        let queryRect = rect ?? CGRect(origin: .zero, size: fixture.contentSize)

        return fixture.layout.layoutAttributesForElements(in: queryRect) ?? []
    }

    @Test func contentSizeIncludesAllHeaderAndFooterHeights() {
        let fixture = makeGrid()
        let dataSource = fixture.dataSource
        let delegate = fixture.delegate

        let expectedWidth = CGFloat(dataSource.columns) * delegate.columnWidth
        let rowsHeight = CGFloat(dataSource.rowCounts.reduce(0, +)) * delegate.rowHeight
        let sectionChrome = CGFloat(dataSource.sections) * (delegate.sectionHeaderHeight + delegate.sectionFooterHeight)
        let expectedHeight = delegate.gridHeaderHeight + delegate.gridFooterHeight + sectionChrome + rowsHeight

        #expect(fixture.contentSize.width == expectedWidth)
        #expect(fixture.contentSize.height == expectedHeight)
    }

    @Test func layoutProducesSupplementaryAttributesForEveryKind() {
        let fixture = makeGrid()
        let columns = fixture.dataSource.columns
        let sections = fixture.dataSource.sections

        let supplementary = attributes(in: fixture).filter { $0.representedElementCategory == .supplementaryView }
        let countsByKind = Dictionary(grouping: supplementary, by: { $0.representedElementKind ?? "" }).mapValues(\.count)

        #expect(countsByKind[SwiftGridElementKindHeader] == columns)
        #expect(countsByKind[SwiftGridElementKindFooter] == columns)
        #expect(countsByKind[SwiftGridElementKindSectionHeader] == columns * sections)
        #expect(countsByKind[SwiftGridElementKindSectionFooter] == columns * sections)
    }

    @Test func headerViewsAreDequeuedThroughTheDataSource() {
        let fixture = makeGrid()

        let visibleHeaders = fixture.grid.collectionView.visibleSupplementaryViews(ofKind: SwiftGridElementKindHeader)

        #expect(!visibleHeaders.isEmpty)
        #expect(visibleHeaders.allSatisfy { type(of: $0) == SwiftGridReusableView.self })
    }

    @Test func frozenColumnsStayVisibleWhenScrolledHorizontally() {
        let fixture = makeGrid()

        // Scroll so unfrozen columns 0/1 (x 0-200) would be fully off screen.
        let offset = CGPoint(x: 250, y: 0)
        fixture.grid.setContentOffset(offset, animated: false)
        fixture.grid.layoutIfNeeded()

        let visibleRect = CGRect(origin: offset, size: fixture.grid.bounds.size)
        let cells = attributes(in: fixture, rect: visibleRect).filter { $0.representedElementCategory == .cell && $0.indexPath.section == 0 }
        let visibleColumns = Set(cells.filter { $0.frame.intersects(visibleRect) }.map { $0.indexPath.item % fixture.dataSource.columns })

        #expect(visibleColumns.contains(0), "frozen column 0 should remain pinned on screen")
        #expect(visibleColumns.contains(1), "frozen column 1 should remain pinned on screen")
    }

    @Test func frozenRowStaysVisibleWhenScrolledVertically() {
        let fixture = makeGrid()

        // Scroll so section 0's first row (y 65-115) would be fully off screen.
        let offset = CGPoint(x: 0, y: 180)
        fixture.grid.setContentOffset(offset, animated: false)
        fixture.grid.layoutIfNeeded()

        let visibleRect = CGRect(origin: offset, size: fixture.grid.bounds.size)
        let cells = attributes(in: fixture, rect: visibleRect).filter { $0.representedElementCategory == .cell && $0.indexPath.section == 0 }
        let visibleRows = Set(cells.filter { $0.frame.intersects(visibleRect) }.map { $0.indexPath.item / fixture.dataSource.columns })

        #expect(visibleRows.contains(0), "frozen row 0 should remain pinned on screen")
    }

    @Test func groupedHeadersSpanTheirColumnGroupings() {
        let groupings = [[1, 2], [3, 4]]
        let fixture = makeGrid(groupings: groupings)

        let groupedAttributes = attributes(in: fixture)
            .filter { $0.representedElementKind == SwiftGridElementKindGroupedHeader }
            .sorted { $0.indexPath.item < $1.indexPath.item }

        #expect(groupedAttributes.count == groupings.count)
        for (attribute, grouping) in zip(groupedAttributes, groupings) {
            let expectedWidth = CGFloat(grouping[1] - grouping[0] + 1) * fixture.delegate.columnWidth
            #expect(attribute.frame.width == expectedWidth)
        }
    }

    @Test func headerSelectionIsTrackedPerElementKind() {
        let fixture = makeGrid()
        let indexPath = IndexPath(forSGRow: 0, atColumn: 3, inSection: 0)

        fixture.grid.selectHeaderAtIndexPath(indexPath)
        #expect(fixture.grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindHeader) == [indexPath])
        #expect(fixture.grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindFooter).isEmpty)

        fixture.grid.deselectHeaderAtIndexPath(indexPath)
        #expect(fixture.grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindHeader).isEmpty)
    }
}
