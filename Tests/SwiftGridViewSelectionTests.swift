// SwiftGridViewSelectionTests.swift
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

// MARK: - Shared Fixture

/// Full-feature grid wired to `SGMockRecordingDelegate`, so tests can assert both
/// the grid's internal selection state and what it forwarded to the delegate.
@MainActor
private struct SelectionFixture {
    let grid: SwiftGridView
    let dataSource: SGMockFeatureRichDataSource
    let delegate: SGMockRecordingDelegate

    var columns: Int { dataSource.columns }

    /// Builds a reusable view standing in for one the grid vended: the grid's
    /// delegate methods read `elementKind`/`indexPath` off the view itself.
    func reusableView(kind: String, at indexPath: IndexPath) -> SwiftGridReusableView {
        let view = SwiftGridReusableView(frame: CGRect(x: 0, y: 0, width: 100, height: 25))
        view.delegate = grid
        view.elementKind = kind
        view.indexPath = indexPath

        return view
    }
}

@MainActor
private func makeSelectionFixture(rowSelection: Bool = false, groupings: [[Int]] = [[0, 1], [2, 3]]) -> SelectionFixture {
    let grid = SwiftGridView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    let dataSource = SGMockFeatureRichDataSource()
    let delegate = SGMockRecordingDelegate()
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

    grid.rowSelectionEnabled = rowSelection
    grid.reloadData()
    grid.layoutIfNeeded()

    return SelectionFixture(grid: grid, dataSource: dataSource, delegate: delegate)
}

// MARK: - Supplementary View Selection

/// Covers the `SwiftGridReusableViewDelegate` surface: every element kind's
/// selection and highlight path, in both single and row selection modes.
@MainActor
@Suite struct SwiftGridViewSupplementarySelectionTests {

    @Test func headerSelectionIsTrackedAndForwardedToTheDelegate() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 2, inSection: 0)
        let view = fixture.reusableView(kind: SwiftGridElementKindHeader, at: indexPath)

        grid.swiftGridReusableView(view, didSelectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindHeader) == [indexPath])
        #expect(fixture.delegate.indexPaths(for: "didSelectHeader") == [indexPath])

        grid.swiftGridReusableView(view, didDeselectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindHeader).isEmpty)
        #expect(fixture.delegate.indexPaths(for: "didDeselectHeader") == [indexPath])
    }

    @Test func footerSelectionIsTrackedAndForwardedToTheDelegate() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 1, inSection: 0)
        let view = fixture.reusableView(kind: SwiftGridElementKindFooter, at: indexPath)

        grid.swiftGridReusableView(view, didSelectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindFooter) == [indexPath])
        #expect(fixture.delegate.indexPaths(for: "didSelectFooter") == [indexPath])

        grid.swiftGridReusableView(view, didDeselectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindFooter).isEmpty)
        #expect(fixture.delegate.indexPaths(for: "didDeselectFooter") == [indexPath])
    }

    @Test func sectionHeaderAndFooterSelectionIsTrackedPerKind() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 1)
        let header = fixture.reusableView(kind: SwiftGridElementKindSectionHeader, at: indexPath)
        let footer = fixture.reusableView(kind: SwiftGridElementKindSectionFooter, at: indexPath)

        grid.swiftGridReusableView(header, didSelectViewAtIndexPath: indexPath)
        grid.swiftGridReusableView(footer, didSelectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader) == [indexPath])
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionFooter) == [indexPath])
        #expect(fixture.delegate.indexPaths(for: "didSelectSectionHeader") == [indexPath])
        #expect(fixture.delegate.indexPaths(for: "didSelectSectionFooter") == [indexPath])

        grid.swiftGridReusableView(header, didDeselectViewAtIndexPath: indexPath)
        grid.swiftGridReusableView(footer, didDeselectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader).isEmpty)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionFooter).isEmpty)
        #expect(fixture.delegate.indexPaths(for: "didDeselectSectionHeader") == [indexPath])
        #expect(fixture.delegate.indexPaths(for: "didDeselectSectionFooter") == [indexPath])
    }

    @Test func groupedHeaderSelectionReportsTheGroupingIndex() {
        let fixture = makeSelectionFixture(groupings: [[0, 1], [2, 3]])
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 1, inSection: 0)
        let view = fixture.reusableView(kind: SwiftGridElementKindGroupedHeader, at: indexPath)

        grid.swiftGridReusableView(view, didSelectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindGroupedHeader) == [indexPath])
        #expect(fixture.delegate.events.contains(SGMockRecordingDelegate.Event("didSelectGroupedHeader", groupIndex: 1)))

        grid.swiftGridReusableView(view, didDeselectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindGroupedHeader).isEmpty)
        #expect(fixture.delegate.events.contains(SGMockRecordingDelegate.Event("didDeselectGroupedHeader", groupIndex: 1)))
    }

    @Test func unknownElementKindsAreIgnored() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        let view = fixture.reusableView(kind: "SomeOtherElementKind", at: indexPath)

        grid.swiftGridReusableView(view, didSelectViewAtIndexPath: indexPath)
        grid.swiftGridReusableView(view, didDeselectViewAtIndexPath: indexPath)
        grid.swiftGridReusableView(view, didHighlightViewAtIndexPath: indexPath)
        grid.swiftGridReusableView(view, didUnhighlightViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: "SomeOtherElementKind").isEmpty)
        #expect(fixture.delegate.events.isEmpty)
    }

    @Test func rowSelectionSelectsEverySectionHeaderColumn() {
        let fixture = makeSelectionFixture(rowSelection: true)
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        let view = fixture.reusableView(kind: SwiftGridElementKindSectionHeader, at: indexPath)

        grid.swiftGridReusableView(view, didSelectViewAtIndexPath: indexPath)

        let selected = grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader)
        #expect(selected.count == fixture.columns)
        #expect(Set(selected.map(\.sgColumn)) == Set(0..<fixture.columns))

        grid.swiftGridReusableView(view, didDeselectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader).isEmpty)
    }

    @Test func rowSelectionSelectsEverySectionFooterColumn() {
        let fixture = makeSelectionFixture(rowSelection: true)
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        let view = fixture.reusableView(kind: SwiftGridElementKindSectionFooter, at: indexPath)

        grid.swiftGridReusableView(view, didSelectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionFooter).count == fixture.columns)

        grid.swiftGridReusableView(view, didDeselectViewAtIndexPath: indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionFooter).isEmpty)
    }

    @Test func sectionHeaderAndFooterConvenienceSelectorsRespectRowSelection() {
        let fixture = makeSelectionFixture(rowSelection: true)
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)

        grid.selectSectionHeaderAtIndexPath(indexPath)
        grid.selectSectionFooterAtIndexPath(indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader).count == fixture.columns)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionFooter).count == fixture.columns)

        grid.deselectSectionHeaderAtIndexPath(indexPath)
        grid.deselectSectionFooterAtIndexPath(indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader).isEmpty)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionFooter).isEmpty)

        // Without row selection the same calls only touch the single index path.
        grid.rowSelectionEnabled = false
        grid.selectSectionHeaderAtIndexPath(indexPath)
        grid.selectSectionFooterAtIndexPath(indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader) == [indexPath])
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionFooter) == [indexPath])

        grid.deselectSectionHeaderAtIndexPath(indexPath)
        grid.deselectSectionFooterAtIndexPath(indexPath)

        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader).isEmpty)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionFooter).isEmpty)
    }

    @Test func highlightingASectionHeaderHighlightsTheWholeRow() throws {
        let fixture = makeSelectionFixture(rowSelection: true)
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        let view = fixture.reusableView(kind: SwiftGridElementKindSectionHeader, at: indexPath)

        grid.swiftGridReusableView(view, didHighlightViewAtIndexPath: indexPath)

        let sibling = try #require(
            grid.supplementaryView(ofElementKind: SwiftGridElementKindSectionHeader, at: IndexPath(forSGRow: 0, atColumn: 1, inSection: 0)))
        #expect(sibling.highlighted)

        grid.swiftGridReusableView(view, didUnhighlightViewAtIndexPath: indexPath)

        #expect(!sibling.highlighted)
    }

    @Test func highlightingNonSectionKindsIsANoOp() {
        let fixture = makeSelectionFixture(rowSelection: true)
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)

        for kind in [SwiftGridElementKindHeader, SwiftGridElementKindFooter, SwiftGridElementKindGroupedHeader] {
            let view = fixture.reusableView(kind: kind, at: indexPath)
            grid.swiftGridReusableView(view, didHighlightViewAtIndexPath: indexPath)
            grid.swiftGridReusableView(view, didUnhighlightViewAtIndexPath: indexPath)
        }

        #expect(fixture.delegate.events.isEmpty)
    }

    @Test func sectionFooterHighlightPropagatesAcrossTheRow() throws {
        let fixture = makeSelectionFixture(rowSelection: true)
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        let view = fixture.reusableView(kind: SwiftGridElementKindSectionFooter, at: indexPath)

        grid.swiftGridReusableView(view, didHighlightViewAtIndexPath: indexPath)

        let sibling = try #require(
            grid.supplementaryView(ofElementKind: SwiftGridElementKindSectionFooter, at: IndexPath(forSGRow: 0, atColumn: 1, inSection: 0)))
        #expect(sibling.highlighted)

        grid.swiftGridReusableView(view, didUnhighlightViewAtIndexPath: indexPath)

        #expect(!sibling.highlighted)
    }

    /// Drives the touch handlers on a real vended view: the grid is its delegate,
    /// so touches must round-trip into the grid's selection cache.
    @Test func touchesOnAVendedViewRoundTripIntoTheGrid() throws {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        let view = try #require(grid.supplementaryView(ofElementKind: SwiftGridElementKindSectionHeader, at: indexPath))

        view.touchesBegan([], with: nil)
        #expect(view.highlighted)

        view.touchesEnded([], with: nil)
        #expect(view.selected)
        #expect(!view.highlighted)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader) == [indexPath])

        // A second tap toggles back off.
        view.touchesBegan([], with: nil)
        view.touchesEnded([], with: nil)
        #expect(!view.selected)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader).isEmpty)

        view.touchesBegan([], with: nil)
        view.touchesCancelled([], with: nil)
        #expect(!view.highlighted)
        #expect(!view.selected)
    }

    @Test func selectedIndexPathsForAnUnsupportedKindIsEmpty() {
        let fixture = makeSelectionFixture()

        #expect(fixture.grid.selectedIndexPathsForSupplementaryView(ofElementKind: "NotAGridElementKind").isEmpty)
    }
}

// MARK: - Cell Selection

/// Covers cell selection: the column/row helpers and the `UICollectionView`
/// delegate callbacks the grid implements on top of them.
@MainActor
@Suite struct SwiftGridViewCellSelectionTests {

    @Test func columnSelectionCoversEveryRowAndTheHeader() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 2, inSection: 0)

        grid.selectColumnAtIndexPath(indexPath, animated: false)

        let selected = grid.indexPathsForSelectedItems.filter { $0.sgSection == 0 }
        #expect(selected.count == fixture.dataSource.rowCounts[0])
        #expect(selected.allSatisfy { $0.sgColumn == 2 })
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindHeader) == [indexPath])

        grid.deselectColumnAtIndexPath(indexPath, animated: false)

        #expect(grid.indexPathsForSelectedItems.isEmpty)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindHeader).isEmpty)
    }

    @Test func columnSelectionCanSkipTheHeader() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 1, inSection: 0)

        grid.selectColumnAtIndexPath(indexPath, animated: false, includeHeader: false)

        #expect(!grid.indexPathsForSelectedItems.isEmpty)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindHeader).isEmpty)

        grid.deselectColumnAtIndexPath(indexPath, animated: false, includeHeader: false)

        #expect(grid.indexPathsForSelectedItems.isEmpty)
    }

    @Test func outOfRangeRowsAreIgnored() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let tooFar = IndexPath(forSGRow: fixture.dataSource.rowCounts[0], atColumn: 0, inSection: 0)
        let negative = IndexPath(forSGRow: -1, atColumn: 0, inSection: 0)

        for indexPath in [tooFar, negative] {
            grid.selectColumnAtIndexPath(indexPath, animated: false)
            grid.deselectColumnAtIndexPath(indexPath, animated: false)
            grid.selectRowAtIndexPath(indexPath, animated: false)
            grid.deselectRowAtIndexPath(indexPath, animated: false)
        }

        #expect(grid.indexPathsForSelectedItems.isEmpty)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindHeader).isEmpty)
    }

    @Test func rowSelectionRoundTripsThroughTheGrid() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 1, atColumn: 0, inSection: 0)

        grid.selectRowAtIndexPath(indexPath, animated: false)

        let selected = grid.indexPathsForSelectedItems
        #expect(selected.count == fixture.columns)
        #expect(selected.allSatisfy { $0.sgRow == 1 && $0.sgSection == 0 })

        grid.deselectRowAtIndexPath(indexPath, animated: false)

        #expect(grid.indexPathsForSelectedItems.isEmpty)
    }

    @Test func cellSelectionCallbacksForwardConvertedIndexPaths() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let sgPath = IndexPath(forSGRow: 2, atColumn: 3, inSection: 0)
        let itemPath = IndexPath(item: 2 * fixture.columns + 3, section: 0)

        grid.collectionView(grid.collectionView, didSelectItemAt: itemPath)
        grid.collectionView(grid.collectionView, didDeselectItemAt: itemPath)

        #expect(fixture.delegate.indexPaths(for: "didSelectCell") == [sgPath])
        #expect(fixture.delegate.indexPaths(for: "didDeselectCell") == [sgPath])
    }

    @Test func singleSelectionClearsPreviouslySelectedCells() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let first = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        let second = IndexPath(forSGRow: 1, atColumn: 1, inSection: 0)

        grid.selectCellAtIndexPath(first, animated: false)
        grid.selectCellAtIndexPath(second, animated: false)
        // The collection view calls this itself on a real tap; drive it directly.
        grid.collectionView(grid.collectionView, didSelectItemAt: IndexPath(item: 1 * fixture.columns + 1, section: 0))

        #expect(grid.indexPathsForSelectedItems == [second])
    }

    @Test func multipleSelectionKeepsEarlierCellsSelected() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        grid.allowsMultipleSelection = true
        let first = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        let second = IndexPath(forSGRow: 1, atColumn: 1, inSection: 0)

        grid.selectCellAtIndexPath(first, animated: false)
        grid.selectCellAtIndexPath(second, animated: false)
        grid.collectionView(grid.collectionView, didSelectItemAt: IndexPath(item: 1 * fixture.columns + 1, section: 0))

        #expect(Set(grid.indexPathsForSelectedItems) == [first, second])
    }

    @Test func rowSelectionExpandsCollectionViewCallbacks() {
        let fixture = makeSelectionFixture(rowSelection: true)
        let grid = fixture.grid
        grid.allowsMultipleSelection = true
        let itemPath = IndexPath(item: 0, section: 0)

        grid.collectionView(grid.collectionView, didSelectItemAt: itemPath)

        #expect(grid.indexPathsForSelectedItems.count == fixture.columns)

        grid.collectionView(grid.collectionView, didDeselectItemAt: itemPath)

        #expect(grid.indexPathsForSelectedItems.isEmpty)
    }

    @Test func rowHighlightCallbacksHighlightEveryCellInTheRow() throws {
        let fixture = makeSelectionFixture(rowSelection: true)
        let grid = fixture.grid
        let itemPath = IndexPath(item: 0, section: 0)

        grid.collectionView(grid.collectionView, didHighlightItemAt: itemPath)

        let sibling = try #require(grid.cellForItem(at: IndexPath(forSGRow: 0, atColumn: 1, inSection: 0)))
        #expect(sibling.isHighlighted)

        grid.collectionView(grid.collectionView, didUnhighlightItemAt: itemPath)

        #expect(!sibling.isHighlighted)
    }

    @Test func highlightCallbacksAreNoOpsWithoutRowSelection() throws {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let itemPath = IndexPath(item: 0, section: 0)

        grid.collectionView(grid.collectionView, didHighlightItemAt: itemPath)

        let sibling = try #require(grid.cellForItem(at: IndexPath(forSGRow: 0, atColumn: 1, inSection: 0)))
        #expect(!sibling.isHighlighted)

        grid.collectionView(grid.collectionView, didUnhighlightItemAt: itemPath)

        #expect(!sibling.isHighlighted)
    }
}

// MARK: - Lookups, Scrolling and Passthrough Properties

@MainActor
@Suite struct SwiftGridViewAccessorTests {

    @Test func visibleItemLookupsConvertBackAndForth() throws {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)

        let visible = grid.indexPathsForVisibleItems
        #expect(!visible.isEmpty)
        #expect(visible.contains(indexPath))

        let cell = try #require(grid.cellForItem(at: indexPath))
        #expect(grid.indexPath(for: cell) == indexPath)

        let offscreen = IndexPath(forSGRow: fixture.dataSource.rowCounts[1] - 1, atColumn: 0, inSection: 1)
        #expect(grid.cellForItem(at: offscreen) == nil)
        #expect(grid.indexPathForItem(at: CGPoint(x: -50, y: -50)) == nil)
    }

    @Test func supplementaryViewLookupReturnsTheVendedView() throws {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid

        let header = try #require(grid.supplementaryView(ofElementKind: SwiftGridElementKindHeader, at: IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)))
        #expect(header.elementKind == SwiftGridElementKindHeader)
        #expect(grid.supplementaryView(ofElementKind: SwiftGridElementKindHeader, at: IndexPath(forSGRow: 9, atColumn: 0, inSection: 0)) == nil)
    }

    @Test func gestureLocationsAreReportedInCollectionViewSpace() {
        let fixture = makeSelectionFixture()
        let recognizer = UITapGestureRecognizer()

        let location = fixture.grid.location(for: recognizer)

        #expect(location == recognizer.location(in: fixture.grid.collectionView))
    }

    @Test func scrollingToACellMovesTheContentOffset() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let lastSection = fixture.dataSource.sections - 1
        let target = IndexPath(forSGRow: fixture.dataSource.rowCounts[lastSection] - 1, atColumn: 0, inSection: lastSection)

        grid.scrollToCellAtIndexPath(target, atScrollPosition: .top, animated: false)

        let maxOffsetY = grid.collectionView.collectionViewLayout.collectionViewContentSize.height - grid.collectionView.frame.height
        #expect(grid.collectionView.contentOffset.y > 0)
        #expect(grid.collectionView.contentOffset.y <= maxOffsetY)
    }

    @Test func scrollingHandlesEveryScrollPosition() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let target = IndexPath(forSGRow: 2, atColumn: 3, inSection: 1)

        for position in [
            UICollectionView.ScrollPosition.top, .bottom, .centeredVertically,
            .left, .right, .centeredHorizontally,
        ] {
            grid.scrollToCellAtIndexPath(target, atScrollPosition: position, animated: false)

            #expect(grid.collectionView.contentOffset.y >= 0)
            #expect(grid.collectionView.contentOffset.x >= 0)
        }
    }

    @Test func scrollingToTheFirstCellClampsToTheTop() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid

        grid.scrollToCellAtIndexPath(IndexPath(forSGRow: 0, atColumn: 0, inSection: 0), atScrollPosition: .top, animated: false)

        #expect(grid.collectionView.contentOffset.y == 0)
    }

    @Test func reloadingCellsKeepsTheGridConsistent() async {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let indexPaths = [
            IndexPath(forSGRow: 0, atColumn: 0, inSection: 0),
            IndexPath(forSGRow: 0, atColumn: 1, inSection: 0),
        ]

        await confirmation("non-animated reload completes") { completed in
            grid.reloadCellsAtIndexPaths(indexPaths, animated: false) { _ in
                completed()
            }
        }

        grid.reloadCellsAtIndexPaths(indexPaths, animated: true)
        grid.layoutIfNeeded()

        #expect(!grid.visibleCells.isEmpty)
    }

    @Test func scrollAndSelectionPropertiesProxyTheCollectionView() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid

        grid.allowsSelection = false
        grid.isDirectionalLockEnabled = true
        grid.bounces = false
        grid.alwaysBounceVertical = true
        grid.alwaysBounceHorizontal = true
        grid.showsHorizontalScrollIndicator = false
        grid.showsVerticalScrollIndicator = false
        grid.scrollsToTop = false
        grid.stickySectionHeaders = true

        #expect(grid.allowsSelection == grid.collectionView.allowsSelection)
        #expect(grid.isDirectionalLockEnabled == grid.collectionView.isDirectionalLockEnabled)
        #expect(grid.bounces == grid.collectionView.bounces)
        #expect(grid.alwaysBounceVertical == grid.collectionView.alwaysBounceVertical)
        #expect(grid.alwaysBounceHorizontal == grid.collectionView.alwaysBounceHorizontal)
        #expect(grid.showsHorizontalScrollIndicator == grid.collectionView.showsHorizontalScrollIndicator)
        #expect(grid.showsVerticalScrollIndicator == grid.collectionView.showsVerticalScrollIndicator)
        #expect(grid.scrollsToTop == grid.collectionView.scrollsToTop)
        #expect(grid.stickySectionHeaders)

        #expect(!grid.isTracking)
        #expect(!grid.isDragging)
        #expect(!grid.isDecelerating)

        let refreshControl = UIRefreshControl()
        grid.refreshControl = refreshControl
        #expect(grid.refreshControl === refreshControl)
        #expect(grid.collectionView.refreshControl === refreshControl)
    }

    @Test func nibRegistrationVendsCellsAndSupplementaryViews() throws {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid
        let nib = UINib(nibName: "SwiftGridTestNibCell", bundle: .module)

        grid.register(nib, forCellWithReuseIdentifier: "NibCellReuseId")
        grid.register(nib, forSupplementaryViewOfKind: SwiftGridElementKindHeader, withReuseIdentifier: "NibHeaderReuseId")

        let cell = grid.dequeueReusableCellWithReuseIdentifier("NibCellReuseId", forIndexPath: IndexPath(forSGRow: 0, atColumn: 0, inSection: 0))
        #expect(cell is SwiftGridTestCell)
    }

    /// The `init(coder:)` paths a storyboard or xib would take.
    @Test func decodedGridAndReusableViewSetUpTheirDefaults() throws {
        func roundTrip<T: UIView>(_ view: T) throws -> T {
            let data = try NSKeyedArchiver.archivedData(withRootObject: view, requiringSecureCoding: false)
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false

            return try #require(unarchiver.decodeObject(of: T.self, forKey: NSKeyedArchiveRootObjectKey))
        }

        let decodedGrid = try roundTrip(SwiftGridView(frame: CGRect(x: 0, y: 0, width: 320, height: 480)))
        #expect(decodedGrid.collectionView != nil)
        #expect(decodedGrid.collectionView.superview === decodedGrid)

        let decodedView = try roundTrip(SwiftGridReusableView(frame: CGRect(x: 0, y: 0, width: 100, height: 25)))
        #expect(decodedView.backgroundColor == UIColor.clear)
        #expect(decodedView.contentView.superview === decodedView)
    }

    @Test func layoutSubviewsKeepsTheCollectionViewMatchingBounds() {
        let fixture = makeSelectionFixture()
        let grid = fixture.grid

        grid.frame = CGRect(x: 0, y: 0, width: 200, height: 300)
        grid.layoutIfNeeded()

        #expect(grid.collectionView.frame == grid.bounds)
    }
}

// MARK: - Protocol Defaults

/// The basic mocks implement none of the optional selection callbacks, so driving
/// the grid with them exercises the protocol extension's default no-ops.
@MainActor
@Suite struct SwiftGridViewDelegateDefaultTests {

    @Test func selectionCallbacksFallBackToProtocolDefaults() {
        let grid = SwiftGridView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let dataSource = SGMockFeatureRichDataSource()
        let delegate = SGMockBasicDelegate()
        dataSource.columnGroupings = [[0, 1], [2, 3]]
        grid.dataSource = dataSource
        grid.delegate = delegate
        grid.register(SwiftGridTestCell.self, forCellWithReuseIdentifier: SwiftGridTestCell.reuseIdentifier())
        grid.reloadData()
        grid.layoutIfNeeded()

        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        for kind in [
            SwiftGridElementKindHeader, SwiftGridElementKindFooter, SwiftGridElementKindGroupedHeader,
            SwiftGridElementKindSectionHeader, SwiftGridElementKindSectionFooter,
        ] {
            let view = SwiftGridReusableView(frame: .zero)
            view.delegate = grid
            view.elementKind = kind
            view.indexPath = indexPath

            grid.swiftGridReusableView(view, didSelectViewAtIndexPath: indexPath)
            grid.swiftGridReusableView(view, didDeselectViewAtIndexPath: indexPath)
        }

        grid.collectionView(grid.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
        grid.collectionView(grid.collectionView, didDeselectItemAt: IndexPath(item: 0, section: 0))

        // Nothing should remain selected once every kind has been deselected again.
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindHeader).isEmpty)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader).isEmpty)
    }
}
