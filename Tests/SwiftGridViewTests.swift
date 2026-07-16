// SwiftGridViewTests.swift
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

// MARK: - SwiftGridCell

@MainActor
@Suite struct SwiftGridCellTests {

    @Test func defaultReuseIdentifier() {
        #expect(SwiftGridCell.reuseIdentifier() == "SwiftGridCellReuseId")
    }

    @Test func initSetsFrameAndClearBackground() {
        let rect = CGRect(x: 0, y: 0, width: 125, height: 35)
        let cell = SwiftGridCell(frame: rect)

        #expect(cell.frame.equalTo(rect))
        #expect(cell.backgroundColor == UIColor.clear)
    }

    // The xib must use an explicit customModule (no customModuleProvider="target"):
    // Xcode's SPM resource pipeline compiles xibs with --module set to the resource
    // bundle name, which does not match the test module the class actually lives in.
    @Test func nibCellLoadsFromBundle() throws {
        let nib = UINib(nibName: "SwiftGridTestNibCell", bundle: .module)
        let cell = try #require(nib.instantiate(withOwner: nil).first as? SwiftGridTestCell)

        #expect(cell.mainLabel != nil)
        #expect(SwiftGridTestCell.reuseIdentifier() == "SwiftGridTestCellReuseId")
    }
}

// MARK: - SwiftGridReusableView

@MainActor
@Suite struct SwiftGridReusableViewTests {

    @Test func defaultReuseIdentifier() {
        #expect(SwiftGridReusableView.reuseIdentifier() == "SwiftGridReusableViewReuseId")
    }

    @Test func backgroundViewsFillAndLayer() {
        let rect = CGRect(x: 0, y: 0, width: 125, height: 35)
        let view = SwiftGridReusableView(frame: rect)
        let redView = UIView()
        redView.backgroundColor = UIColor.red
        view.backgroundView = redView
        let blueView = UIView()
        blueView.backgroundColor = UIColor.blue
        view.selectedBackgroundView = blueView

        view.layoutIfNeeded()

        #expect(view.frame.equalTo(rect))
        #expect(view.contentView.frame.equalTo(rect))
        #expect(view.backgroundView!.frame.equalTo(rect))
        #expect(view.selectedBackgroundView!.frame.equalTo(rect))
        #expect(view.backgroundColor == UIColor.clear)

        // Replacing the background keeps it behind the selected background
        let greenView = UIView()
        greenView.backgroundColor = UIColor.green
        view.backgroundView = greenView

        let backgroundIndex = view.subviews.firstIndex(of: view.backgroundView!)!
        let selectedIndex = view.subviews.firstIndex(of: view.selectedBackgroundView!)!
        #expect(backgroundIndex < selectedIndex)
    }

    @Test func highlightAndSelectionToggleSelectedBackground() {
        let view = SwiftGridReusableView(frame: CGRect(x: 0, y: 0, width: 125, height: 35))
        view.selectedBackgroundView = UIView()

        view.highlighted = true
        #expect(view.selectedBackgroundView?.isHidden == false)
        view.highlighted = false
        #expect(view.selectedBackgroundView?.isHidden == true)
        view.selected = true
        #expect(view.selectedBackgroundView?.isHidden == false)
        view.selected = false
        #expect(view.selectedBackgroundView?.isHidden == true)
    }

    @Test func prepareForReuseResetsState() {
        let view = SwiftGridReusableView(frame: CGRect(x: 0, y: 0, width: 125, height: 35))
        view.selectedBackgroundView = UIView()
        view.selected = true
        view.highlighted = true

        view.prepareForReuse()

        #expect(view.highlighted == false)
        #expect(view.selected == false)
        #expect(view.selectedBackgroundView?.isHidden == true)
    }
}

// MARK: - IndexPath+SwiftGridView

@Suite struct IndexPathExtensionTests {

    @Test func sgIndexPathComponents() {
        let indexPath = IndexPath(forSGRow: 3, atColumn: 4, inSection: 2)

        #expect(indexPath.sgRow == 3)
        #expect(indexPath.sgColumn == 4)
        #expect(indexPath.sgSection == 2)
    }
}

// MARK: - Grid Integration

/// Instantiates a real grid with the basic mocks and drives layout headlessly.
@MainActor
@Suite struct SwiftGridViewIntegrationTests {

    // Retains the mocks: the grid holds dataSource/delegate weakly, so discarding
    // them mid-test would nil the references out from under the grid.
    private struct Fixture {
        let grid: SwiftGridView
        let dataSource: SGMockBasicDataSource
        let delegate: SGMockBasicDelegate
    }

    private func makeGrid() -> Fixture {
        let grid = SwiftGridView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let dataSource = SGMockBasicDataSource()
        let delegate = SGMockBasicDelegate()
        grid.dataSource = dataSource
        grid.delegate = delegate
        grid.register(SwiftGridTestCell.self, forCellWithReuseIdentifier: SwiftGridTestCell.reuseIdentifier())
        grid.reloadData()
        grid.layoutIfNeeded()

        return Fixture(grid: grid, dataSource: dataSource, delegate: delegate)
    }

    @Test func sectionAndItemCountsComeFromDataSource() {
        let fixture = makeGrid()
        let (grid, dataSource) = (fixture.grid, fixture.dataSource)

        #expect(grid.collectionView.numberOfSections == dataSource.sections)
        for section in 0..<dataSource.sections {
            #expect(grid.collectionView.numberOfItems(inSection: section) == dataSource.columns * dataSource.rowCounts[section])
        }
    }

    @Test func contentSizeMatchesColumnWidthsAndRowHeights() {
        let fixture = makeGrid()
        let (grid, dataSource, delegate) = (fixture.grid, fixture.dataSource, fixture.delegate)

        let expectedWidth = CGFloat(dataSource.columns) * delegate.columnWidth
        let expectedHeight = CGFloat(dataSource.rowCounts.reduce(0, +)) * delegate.rowHeight
        let contentSize = grid.collectionView.collectionViewLayout.collectionViewContentSize

        #expect(contentSize.width == expectedWidth)
        #expect(contentSize.height == expectedHeight)
    }

    @Test func visibleCellsAreDequeuedGridCells() {
        let fixture = makeGrid()
        let grid = fixture.grid

        #expect(!grid.visibleCells.isEmpty)
        #expect(grid.visibleCells.allSatisfy { $0 is SwiftGridTestCell })
    }

    @Test func cellSelectionRoundTripsThroughSGIndexPaths() {
        let fixture = makeGrid()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 1, atColumn: 2, inSection: 0)

        grid.selectCellAtIndexPath(indexPath, animated: false)
        #expect(grid.indexPathsForSelectedItems == [indexPath])

        grid.deselectCellAtIndexPath(indexPath, animated: false)
        #expect(grid.indexPathsForSelectedItems.isEmpty)
    }

    @Test func rowSelectionSelectsWholeRow() {
        let fixture = makeGrid()
        let (grid, dataSource) = (fixture.grid, fixture.dataSource)
        grid.rowSelectionEnabled = true

        grid.selectCellAtIndexPath(IndexPath(forSGRow: 0, atColumn: 0, inSection: 0), animated: false)

        let selected = grid.indexPathsForSelectedItems
        #expect(selected.count == dataSource.columns)
        #expect(selected.allSatisfy { $0.sgRow == 0 && $0.sgSection == 0 })
    }

    @Test func indexPathLookupsConvertCoordinates() {
        let fixture = makeGrid()
        let (grid, delegate) = (fixture.grid, fixture.delegate)

        // A point inside the second column of the third row
        let point = CGPoint(x: delegate.columnWidth * 1.5, y: delegate.rowHeight * 2.5)
        let found = grid.indexPathForItem(at: point)

        #expect(found == IndexPath(forSGRow: 2, atColumn: 1, inSection: 0))
    }

    @Test func defaultsDisableOptionalFeatures() {
        // The basic mocks implement none of the optional methods: the protocol
        // defaults must report the features as off.
        let fixture = makeGrid()
        let grid = fixture.grid

        #expect(grid.dataSource?.numberOfFrozenColumnsInDataGridView(grid) == 0)
        #expect(grid.dataSource?.columnGroupingsForDataGridView(grid).isEmpty == true)
        #expect(grid.dataSource?.dataGridView(grid, numberOfFrozenRowsInSection: 0) == 0)
        #expect(grid.delegate?.heightForGridHeaderInDataGridView(grid) == 0)
        #expect(grid.delegate?.heightForGridFooterInDataGridView(grid) == 0)
        #expect(grid.delegate?.dataGridView(grid, heightOfHeaderInSection: 0) == 0)
        #expect(grid.delegate?.dataGridView(grid, heightOfFooterInSection: 0) == 0)
    }

    @Test func reloadDataResetsCachedCounts() {
        let fixture = makeGrid()
        let (grid, dataSource) = (fixture.grid, fixture.dataSource)

        #expect(grid.collectionView.numberOfSections == dataSource.sections)

        grid.reloadData()
        grid.layoutIfNeeded()

        #expect(grid.collectionView.numberOfSections == dataSource.sections)
        #expect(!grid.visibleCells.isEmpty)
    }
}
