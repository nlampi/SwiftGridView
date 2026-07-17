// SGMockFeatureRichDataSource.swift
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
import SwiftGridView
import UIKit

/// Datasource exercising the full feature surface: grid headers/footers, section
/// headers/footers, frozen rows and columns, and optional column groupings.
/// All supplementary views dequeue plain `SwiftGridReusableView`s, which the test
/// registers for every element kind.
@MainActor
final class SGMockFeatureRichDataSource: SwiftGridViewDataSource {

    let sections: Int = 2
    let columns: Int = 6
    var rowCounts: [Int] = [4, 6]
    var frozenColumns: Int = 2
    var frozenRowsPerSection: Int = 1
    var columnGroupings: [[Int]] = []

    func numberOfSectionsInDataGridView(_ dataGridView: SwiftGridView) -> Int {

        return self.sections
    }

    func numberOfColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int {

        return self.columns
    }

    func dataGridView(_ dataGridView: SwiftGridView, numberOfRowsInSection section: Int) -> Int {

        return self.rowCounts[section]
    }

    func numberOfFrozenColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int {

        return self.frozenColumns
    }

    func dataGridView(_ dataGridView: SwiftGridView, numberOfFrozenRowsInSection section: Int) -> Int {

        return self.frozenRowsPerSection
    }

    func columnGroupingsForDataGridView(_ dataGridView: SwiftGridView) -> [[Int]] {

        return self.columnGroupings
    }

    func dataGridView(_ dataGridView: SwiftGridView, cellAtIndexPath indexPath: IndexPath) -> SwiftGridCell {

        return dataGridView.dequeueReusableCellWithReuseIdentifier(SwiftGridTestCell.reuseIdentifier(), forIndexPath: indexPath)
    }

    func dataGridView(_ dataGridView: SwiftGridView, gridHeaderViewForColumn column: Int) -> SwiftGridReusableView {

        return dataGridView.dequeueReusableSupplementaryViewOfKind(
            SwiftGridElementKindHeader, withReuseIdentifier: SwiftGridReusableView.reuseIdentifier(), atColumn: column)
    }

    func dataGridView(_ dataGridView: SwiftGridView, gridFooterViewForColumn column: Int) -> SwiftGridReusableView {

        return dataGridView.dequeueReusableSupplementaryViewOfKind(
            SwiftGridElementKindFooter, withReuseIdentifier: SwiftGridReusableView.reuseIdentifier(), atColumn: column)
    }

    func dataGridView(_ dataGridView: SwiftGridView, groupedHeaderViewFor columnGrouping: [Int], at index: Int) -> SwiftGridReusableView {

        return dataGridView.dequeueReusableSupplementaryViewOfKind(
            SwiftGridElementKindGroupedHeader, withReuseIdentifier: SwiftGridReusableView.reuseIdentifier(), atColumn: index)
    }

    func dataGridView(_ dataGridView: SwiftGridView, sectionHeaderCellAtIndexPath indexPath: IndexPath) -> SwiftGridReusableView {

        return dataGridView.dequeueReusableSupplementaryViewOfKind(
            SwiftGridElementKindSectionHeader, withReuseIdentifier: SwiftGridReusableView.reuseIdentifier(), forIndexPath: indexPath)
    }

    func dataGridView(_ dataGridView: SwiftGridView, sectionFooterCellAtIndexPath indexPath: IndexPath) -> SwiftGridReusableView {

        return dataGridView.dequeueReusableSupplementaryViewOfKind(
            SwiftGridElementKindSectionFooter, withReuseIdentifier: SwiftGridReusableView.reuseIdentifier(), forIndexPath: indexPath)
    }
}

/// Delegate companion to `SGMockFeatureRichDataSource` providing non-zero heights
/// for every header and footer kind.
@MainActor
final class SGMockFeatureRichDelegate: SwiftGridViewDelegate {

    let columnWidth: CGFloat = 100
    let rowHeight: CGFloat = 50
    var gridHeaderHeight: CGFloat = 40
    var gridFooterHeight: CGFloat = 30
    var sectionHeaderHeight: CGFloat = 25
    var sectionFooterHeight: CGFloat = 20

    func dataGridView(_ dataGridView: SwiftGridView, widthOfColumnAtIndex columnIndex: Int) -> CGFloat {

        return self.columnWidth
    }

    func dataGridView(_ dataGridView: SwiftGridView, heightOfRowAtIndexPath indexPath: IndexPath) -> CGFloat {

        return self.rowHeight
    }

    func heightForGridHeaderInDataGridView(_ dataGridView: SwiftGridView) -> CGFloat {

        return self.gridHeaderHeight
    }

    func heightForGridFooterInDataGridView(_ dataGridView: SwiftGridView) -> CGFloat {

        return self.gridFooterHeight
    }

    func dataGridView(_ dataGridView: SwiftGridView, heightOfHeaderInSection section: Int) -> CGFloat {

        return self.sectionHeaderHeight
    }

    func dataGridView(_ dataGridView: SwiftGridView, heightOfFooterInSection section: Int) -> CGFloat {

        return self.sectionFooterHeight
    }
}
