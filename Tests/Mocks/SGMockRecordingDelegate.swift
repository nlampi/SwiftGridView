// SGMockRecordingDelegate.swift
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

/// Delegate that implements every optional selection callback and records the
/// index paths it was handed, so tests can assert what the grid forwarded.
///
/// Sizing matches `SGMockFeatureRichDelegate` so it can stand in for it.
@MainActor
final class SGMockRecordingDelegate: SwiftGridViewDelegate {

    /// One recorded callback: the event name and the index path (or grouped
    /// column index) it carried.
    struct Event: Equatable {
        let name: String
        let indexPath: IndexPath?
        let groupIndex: Int?
        let scale: CGFloat?

        init(_ name: String, _ indexPath: IndexPath? = nil, groupIndex: Int? = nil, scale: CGFloat? = nil) {
            self.name = name
            self.indexPath = indexPath
            self.groupIndex = groupIndex
            self.scale = scale
        }
    }

    var columnWidth: CGFloat = 100
    var rowHeight: CGFloat = 50
    var gridHeaderHeight: CGFloat = 40
    var gridFooterHeight: CGFloat = 30
    var sectionHeaderHeight: CGFloat = 25
    var sectionFooterHeight: CGFloat = 20

    private(set) var events: [Event] = []

    func indexPaths(for name: String) -> [IndexPath] {

        return self.events.filter { $0.name == name }.compactMap(\.indexPath)
    }

    func scales(for name: String) -> [CGFloat] {

        return self.events.filter { $0.name == name }.compactMap(\.scale)
    }

    func names(matching prefix: String) -> [String] {

        return self.events.map(\.name).filter { $0.hasPrefix(prefix) }
    }

    // MARK: - Sizing

    func dataGridView(_ dataGridView: SwiftGridView, widthOfColumnAtIndex columnIndex: Int) -> CGFloat {

        return self.columnWidth
    }

    /// Counts how often the layout asks for a row height, so a test can tell
    /// whether the content height was rebuilt or reused.
    private(set) var rowHeightCallCount = 0

    func dataGridView(_ dataGridView: SwiftGridView, heightOfRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        self.rowHeightCallCount += 1

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

    // MARK: - Selection

    func dataGridView(_ dataGridView: SwiftGridView, didSelectCellAtIndexPath indexPath: IndexPath) {
        self.events.append(Event("didSelectCell", indexPath))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didDeselectCellAtIndexPath indexPath: IndexPath) {
        self.events.append(Event("didDeselectCell", indexPath))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didSelectHeaderAtIndexPath indexPath: IndexPath) {
        self.events.append(Event("didSelectHeader", indexPath))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didDeselectHeaderAtIndexPath indexPath: IndexPath) {
        self.events.append(Event("didDeselectHeader", indexPath))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didSelectFooterAtIndexPath indexPath: IndexPath) {
        self.events.append(Event("didSelectFooter", indexPath))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didDeselectFooterAtIndexPath indexPath: IndexPath) {
        self.events.append(Event("didDeselectFooter", indexPath))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didSelectSectionHeaderAtIndexPath indexPath: IndexPath) {
        self.events.append(Event("didSelectSectionHeader", indexPath))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didDeselectSectionHeaderAtIndexPath indexPath: IndexPath) {
        self.events.append(Event("didDeselectSectionHeader", indexPath))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didSelectSectionFooterAtIndexPath indexPath: IndexPath) {
        self.events.append(Event("didSelectSectionFooter", indexPath))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didDeselectSectionFooterAtIndexPath indexPath: IndexPath) {
        self.events.append(Event("didDeselectSectionFooter", indexPath))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didSelectGroupedHeader columnGrouping: [Int], at index: Int) {
        self.events.append(Event("didSelectGroupedHeader", groupIndex: index))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didDeselectGroupedHeader columnGrouping: [Int], at index: Int) {
        self.events.append(Event("didDeselectGroupedHeader", groupIndex: index))
    }

    // MARK: - Zoom

    func dataGridViewWillBeginZooming(_ dataGridView: SwiftGridView) {
        self.events.append(Event("zoomWillBegin"))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didChangeZoomScale zoomScale: CGFloat) {
        self.events.append(Event("zoomDidChange", scale: zoomScale))
    }

    func dataGridView(_ dataGridView: SwiftGridView, didEndZoomingAtScale scale: CGFloat) {
        self.events.append(Event("zoomDidEnd", scale: scale))
    }
}
