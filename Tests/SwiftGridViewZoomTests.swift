// SwiftGridViewZoomTests.swift
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

// MARK: - Fixture

@MainActor
private struct ZoomFixture {
    let grid: SwiftGridView
    let dataSource: SGMockFeatureRichDataSource
    let delegate: SGMockRecordingDelegate

    var contentSize: CGSize { grid.collectionView.collectionViewLayout.collectionViewContentSize }
}

@MainActor
private func makeZoomFixture() -> ZoomFixture {
    let grid = SwiftGridView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    let dataSource = SGMockFeatureRichDataSource()
    let delegate = SGMockRecordingDelegate()
    grid.dataSource = dataSource
    grid.delegate = delegate

    grid.register(SwiftGridTestCell.self, forCellWithReuseIdentifier: SwiftGridTestCell.reuseIdentifier())
    for kind in [
        SwiftGridElementKindHeader, SwiftGridElementKindFooter, SwiftGridElementKindGroupedHeader,
        SwiftGridElementKindSectionHeader, SwiftGridElementKindSectionFooter,
    ] {
        grid.register(SwiftGridReusableView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: SwiftGridReusableView.reuseIdentifier())
    }

    grid.pinchExpandEnabled = true
    grid.reloadData()
    grid.layoutIfNeeded()

    return ZoomFixture(grid: grid, dataSource: dataSource, delegate: delegate)
}

/// Stands in for a live pinch: `state`, `numberOfTouches` and `location(in:)` are
/// all driven by the touch sequence on a real recognizer, and a recognizer built
/// outside one reports `.possible` with zero touches.
private final class StubPinchGestureRecognizer: UIPinchGestureRecognizer {
    private let touches: Int
    private let stubbedState: UIGestureRecognizer.State
    private let stubbedLocation: CGPoint

    init(scale: CGFloat = 1.0, state: UIGestureRecognizer.State = .changed, touches: Int = 2, location: CGPoint = .zero) {
        self.touches = touches
        self.stubbedState = state
        self.stubbedLocation = location
        super.init(target: nil, action: nil)
        self.scale = scale
    }

    override var numberOfTouches: Int {

        return self.touches
    }

    override var state: UIGestureRecognizer.State {
        get {

            return self.stubbedState
        }
        set {}
    }

    override func location(in view: UIView?) -> CGPoint {

        return self.stubbedLocation
    }
}

// MARK: - Pinch Zoom

/// Covers the pinch handling rewritten for issue #34: cumulative scaling,
/// clamping, damping, stops, centroid anchoring and the delegate callbacks.
@MainActor
@Suite struct SwiftGridViewZoomTests {

    @Test func zoomStartsAtIdentity() {
        let fixture = makeZoomFixture()

        #expect(fixture.grid.zoomScale == 1.0)
        #expect(fixture.grid.zoomAxis == .horizontal)
    }

    /// The bug at the heart of the old implementation: `scale` is relative to the
    /// start of each gesture, so a second pinch used to snap the grid back to 1x.
    @Test func zoomAccumulatesAcrossSeparateGestures() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let originalWidth = fixture.contentSize.width

        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 2.0))
        #expect(grid.zoomScale == 2.0)
        #expect(fixture.contentSize.width == originalWidth * 2)

        // A fresh gesture starts from `scale == 2` again; the grid must build on
        // the zoom it already has rather than resetting to it.
        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 2.0))
        #expect(grid.zoomScale == 4.0)
        #expect(fixture.contentSize.width == originalWidth * 4)
    }

    @Test func pinchingBeyondTheLimitsClampsInsteadOfStopping() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 20.0))
        #expect(grid.zoomScale == grid.maximumZoomScale)

        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 0.001))
        #expect(grid.zoomScale == grid.minimumZoomScale)
    }

    @Test func zoomLimitsAreConfigurable() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.minimumZoomScale = 0.75
        grid.maximumZoomScale = 2.0

        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 10.0))
        #expect(grid.zoomScale == 2.0)

        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 0.01))
        #expect(grid.zoomScale == 0.75)
    }

    @Test func zoomSpeedDampensTheGesture() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomSpeed = 0.5

        // A 2x pinch at half speed is a 1.5x zoom.
        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 2.0))

        #expect(grid.zoomScale == 1.5)
    }

    @Test func zoomSnapsToConfiguredStops() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomStops = [0.75, 1.0, 1.5, 2.0]

        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 1.8))
        #expect(grid.zoomScale == 2.0)

        grid.zoomScale = 1.0
        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 1.3))
        #expect(grid.zoomScale == 1.5)
    }

    @Test func stopsOutsideTheZoomRangeAreIgnored() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.maximumZoomScale = 2.0
        grid.zoomStops = [1.0, 2.0, 8.0]

        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 10.0))

        #expect(grid.zoomScale == 2.0)
    }

    @Test func aLiftedFingerDoesNotChangeTheZoom() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 2.0, touches: 1))

        #expect(grid.zoomScale == 1.0)
    }

    @Test func zoomAnchorsOnThePinchCentroid() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.setContentOffset(CGPoint(x: 100, y: 0), animated: false)
        grid.layoutIfNeeded()

        // Content point 200 sits 100pt into the viewport; at 2x it moves to 400,
        // so the offset has to follow it to 300 to keep it under the fingers.
        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 2.0, location: CGPoint(x: 200, y: 0)))

        #expect(grid.collectionView.contentOffset.x == 300)
    }

    @Test func anchoredOffsetsStayWithinTheContent() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        // Anchoring at the far edge would push the offset past the content.
        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 5.0, location: CGPoint(x: 600, y: 0)))

        let maxX = fixture.contentSize.width - grid.collectionView.bounds.width
        #expect(grid.collectionView.contentOffset.x >= 0)
        #expect(grid.collectionView.contentOffset.x <= maxX)
    }

    @Test func twoFingerTapResetsTheZoom() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let originalWidth = fixture.contentSize.width

        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 3.0))
        #expect(fixture.contentSize.width != originalWidth)

        grid.handleTwoFingerTapGesture(UITapGestureRecognizer())
        #expect(grid.zoomScale == 1.0)
        #expect(fixture.contentSize.width == originalWidth)

        // Tapping again with the zoom already reset changes nothing.
        grid.handleTwoFingerTapGesture(UITapGestureRecognizer())
        #expect(grid.zoomScale == 1.0)
    }

    @Test func enablingAndDisablingPinchManagesTheRecognizers() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        #expect((grid.collectionView.gestureRecognizers ?? []).contains { $0 is UIPinchGestureRecognizer })

        grid.pinchExpandEnabled = false

        #expect((grid.collectionView.gestureRecognizers ?? []).allSatisfy { !($0 is UIPinchGestureRecognizer) })
    }

    // MARK: Zoom Axis

    @Test func horizontalZoomLeavesRowHeightsAlone() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let original = fixture.contentSize

        grid.zoomScale = 2.0

        #expect(fixture.contentSize.width == original.width * 2)
        #expect(fixture.contentSize.height == original.height)
    }

    @Test func bothAxesScaleRowsAndColumnsTogether() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let original = fixture.contentSize
        grid.zoomAxis = .both

        grid.zoomScale = 2.0

        #expect(fixture.contentSize.width == original.width * 2)
        #expect(fixture.contentSize.height == original.height * 2)
    }

    @Test func cellsAndSupplementaryViewsGrowWithAVerticalZoom() throws {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let layout = grid.collectionView.collectionViewLayout
        let itemPath = IndexPath(item: 0, section: 0)
        let originalCell = try #require(layout.layoutAttributesForItem(at: itemPath)).frame
        let originalHeader = try #require(
            layout.layoutAttributesForSupplementaryView(ofKind: SwiftGridElementKindHeader, at: itemPath)
        ).frame

        grid.zoomAxis = .both
        grid.zoomScale = 2.0

        let zoomedCell = try #require(layout.layoutAttributesForItem(at: itemPath)).frame
        let zoomedHeader = try #require(
            layout.layoutAttributesForSupplementaryView(ofKind: SwiftGridElementKindHeader, at: itemPath)
        ).frame

        #expect(zoomedCell.height == originalCell.height * 2)
        #expect(zoomedCell.width == originalCell.width * 2)
        #expect(zoomedHeader.height == originalHeader.height * 2)
    }

    @Test func verticalZoomLeavesColumnWidthsAlone() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let original = fixture.contentSize
        grid.zoomAxis = .vertical

        grid.zoomScale = 2.0

        #expect(fixture.contentSize.width == original.width)
        #expect(fixture.contentSize.height == original.height * 2)
    }

    @Test func verticalZoomGrowsCellHeightsOnly() throws {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let layout = grid.collectionView.collectionViewLayout
        let itemPath = IndexPath(item: 0, section: 0)
        let original = try #require(layout.layoutAttributesForItem(at: itemPath)).frame

        grid.zoomAxis = .vertical
        grid.zoomScale = 2.0

        let zoomed = try #require(layout.layoutAttributesForItem(at: itemPath)).frame
        #expect(zoomed.height == original.height * 2)
        #expect(zoomed.width == original.width)
    }

    @Test func verticalZoomAnchorsVerticallyOnly() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomAxis = .vertical
        grid.setContentOffset(CGPoint(x: 100, y: 100), animated: false)
        grid.layoutIfNeeded()

        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 2.0, location: CGPoint(x: 200, y: 200)))

        // The horizontal offset is untouched; the vertical one follows the anchor.
        #expect(grid.collectionView.contentOffset.x == 100)
        #expect(grid.collectionView.contentOffset.y == 300)
    }

    @Test func eachAxisReportsWhatItScales() {
        #expect(SwiftGridZoomAxis.horizontal.scalesHorizontally)
        #expect(!SwiftGridZoomAxis.horizontal.scalesVertically)
        #expect(!SwiftGridZoomAxis.vertical.scalesHorizontally)
        #expect(SwiftGridZoomAxis.vertical.scalesVertically)
        #expect(SwiftGridZoomAxis.both.scalesHorizontally)
        #expect(SwiftGridZoomAxis.both.scalesVertically)
    }

    @Test func changingTheAxisReappliesTheCurrentZoom() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let original = fixture.contentSize

        grid.zoomScale = 2.0
        #expect(fixture.contentSize.height == original.height)

        grid.zoomAxis = .both

        #expect(fixture.contentSize.height == original.height * 2)
        #expect(grid.zoomScale == 2.0)
    }

    // MARK: Delegate Callbacks

    @Test func zoomCallbacksReportTheGesturesLifecycle() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        grid.handlePinchGesture(StubPinchGestureRecognizer(state: .began))
        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 2.0, state: .changed))
        grid.handlePinchGesture(StubPinchGestureRecognizer(state: .ended))

        #expect(fixture.delegate.names(matching: "zoom") == ["zoomWillBegin", "zoomDidChange", "zoomDidEnd"])
        #expect(fixture.delegate.scales(for: "zoomDidChange") == [2.0])
        #expect(fixture.delegate.scales(for: "zoomDidEnd") == [2.0])
    }

    @Test func cancelledGesturesStillReportAnEnd() {
        let fixture = makeZoomFixture()

        fixture.grid.handlePinchGesture(StubPinchGestureRecognizer(state: .cancelled))

        #expect(fixture.delegate.names(matching: "zoom") == ["zoomDidEnd"])
    }

    @Test func settingZoomScaleDirectlyNotifiesTheDelegate() {
        let fixture = makeZoomFixture()

        fixture.grid.zoomScale = 1.5

        #expect(fixture.delegate.scales(for: "zoomDidChange") == [1.5])
    }

    @Test func settingZoomScaleClampsAndSkipsRedundantChanges() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        grid.zoomScale = 100
        #expect(grid.zoomScale == grid.maximumZoomScale)

        // Re-applying the same scale must not fire the delegate again.
        grid.zoomScale = 100
        #expect(fixture.delegate.scales(for: "zoomDidChange") == [grid.maximumZoomScale])
    }

    @Test func unchangedPinchesDoNotNotifyTheDelegate() {
        let fixture = makeZoomFixture()

        fixture.grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 1.0, state: .changed))

        #expect(fixture.delegate.scales(for: "zoomDidChange").isEmpty)
    }
}

// MARK: - invalidateLayout

@MainActor
@Suite struct SwiftGridViewInvalidateLayoutTests {

    @Test func invalidateLayoutPicksUpNewSizingWithoutAReload() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let original = fixture.contentSize

        fixture.delegate.columnWidth *= 2
        fixture.delegate.rowHeight *= 2
        grid.invalidateLayout()
        grid.layoutIfNeeded()

        #expect(fixture.contentSize.width == original.width * 2)
        #expect(fixture.contentSize.height > original.height)
    }

    @Test func invalidateLayoutPreservesTheZoomScale() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomScale = 2.0
        let zoomedWidth = fixture.contentSize.width

        grid.invalidateLayout()
        grid.layoutIfNeeded()

        #expect(grid.zoomScale == 2.0)
        #expect(fixture.contentSize.width == zoomedWidth)
    }
}
