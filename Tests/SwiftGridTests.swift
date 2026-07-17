// SwiftGridTests.swift
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

import SwiftUI
import Testing
import UIKit

@testable import SwiftGridView

// MARK: - SwiftGrid (SwiftUI)

/// Covers the SwiftUI wrapper: coordinator retention semantics and the hosted
/// make/update lifecycle including the reloadToken contract.
@MainActor
@Suite struct SwiftGridTests {

    private final class ConfigureBox {
        var callCount = 0
    }

    private func findGridView(in view: UIView) -> SwiftGridView? {
        if let gridView = view as? SwiftGridView {
            return gridView
        }
        for subview in view.subviews {
            if let found = findGridView(in: subview) {
                return found
            }
        }

        return nil
    }

    @Test func coordinatorRetainsDataSourceAndDelegate() {
        let dataSource = SGMockBasicDataSource()
        let delegate = SGMockBasicDelegate()
        let grid = SwiftGrid(dataSource: dataSource, delegate: delegate)

        let coordinator = grid.makeCoordinator()

        #expect(coordinator.dataSource === dataSource)
        #expect(coordinator.delegate === delegate)
    }

    @Test func hostedGridConfiguresDisplaysAndReloadsOnTokenChange() throws {
        let dataSource = SGMockFeatureRichDataSource()
        dataSource.frozenColumns = 0
        dataSource.frozenRowsPerSection = 0
        let delegate = SGMockBasicDelegate()
        let box = ConfigureBox()

        func makeRootView(reloadToken: Int) -> SwiftGrid {
            SwiftGrid(dataSource: dataSource, delegate: delegate, reloadToken: reloadToken) { gridView in
                box.callCount += 1
                gridView.register(SwiftGridTestCell.self, forCellWithReuseIdentifier: SwiftGridTestCell.reuseIdentifier())
            }
        }

        let host = UIHostingController(rootView: makeRootView(reloadToken: 1))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.isHidden = false
        window.layoutIfNeeded()

        let gridView = try #require(findGridView(in: host.view), "the hosted hierarchy should contain the SwiftGridView")
        #expect(box.callCount == 1, "configure should run exactly once, at makeUIView time")
        #expect(gridView.dataSource === dataSource)
        #expect(gridView.delegate === delegate)
        #expect(gridView.collectionView.numberOfSections == dataSource.sections)
        let columns = dataSource.columns
        #expect(gridView.collectionView.numberOfItems(inSection: 0) == columns * dataSource.rowCounts[0])

        // A changed reloadToken must trigger reloadData and pick up new counts.
        dataSource.rowCounts = [2, 6]
        host.rootView = makeRootView(reloadToken: 2)
        window.layoutIfNeeded()

        #expect(gridView.collectionView.numberOfItems(inSection: 0) == columns * 2)

        // An unchanged token must NOT reload, even if the data changed underneath.
        dataSource.rowCounts = [5, 6]
        host.rootView = makeRootView(reloadToken: 2)
        window.layoutIfNeeded()

        #expect(gridView.collectionView.numberOfItems(inSection: 0) == columns * 2, "same token should not trigger a reload")
        #expect(box.callCount == 1, "configure should not run again on updates")
    }
}
