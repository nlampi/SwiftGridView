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
///
/// `scale` models UIKit faithfully, including the rebasing an assignment does:
/// the real recognizer reports the separation relative to the gesture's start,
/// and writing to `scale` moves that reference point. A handler that resets
/// `scale` therefore sees only small deltas afterwards, which a stub returning a
/// fixed number would hide.
private final class StubPinchGestureRecognizer: UIPinchGestureRecognizer {
    var stubState: UIGestureRecognizer.State
    var stubTouches: Int
    var stubLocation: CGPoint

    /// Current finger separation over the separation when the pinch began.
    var fingerScale: CGFloat
    private var scaleBaseline: CGFloat = 1.0

    init(scale: CGFloat = 1.0, state: UIGestureRecognizer.State = .changed, touches: Int = 2, location: CGPoint = .zero) {
        self.fingerScale = scale
        self.stubState = state
        self.stubTouches = touches
        self.stubLocation = location
        super.init(target: nil, action: nil)
    }

    override var scale: CGFloat {
        get {

            return self.fingerScale / self.scaleBaseline
        }
        set {
            self.scaleBaseline = newValue == 0 ? 1.0 : self.fingerScale / newValue
        }
    }

    override var state: UIGestureRecognizer.State {
        get {

            return self.stubState
        }
        set {}
    }

    override var numberOfTouches: Int {

        return self.stubTouches
    }

    override func location(in view: UIView?) -> CGPoint {

        return self.stubLocation
    }
}

/// Drives a full pinch the way UIKit does: a `.began`, one `.changed` per
/// sampled finger position, then an `.ended`. Tests must not fire a bare
/// `.changed`, since the zoom is derived from where the gesture began.
@MainActor
private func pinch(_ grid: SwiftGridView, through scales: [CGFloat], at location: CGPoint = .zero) {
    // A single recognizer for the whole gesture: UIKit reuses one, and the
    // handler's reading of `scale` depends on that continuity.
    let recognizer = StubPinchGestureRecognizer(state: .began, location: location)
    grid.handlePinchGesture(recognizer)

    recognizer.stubState = .changed
    for scale in scales {
        recognizer.fingerScale = scale
        grid.handlePinchGesture(recognizer)
    }

    recognizer.stubState = .ended
    grid.handlePinchGesture(recognizer)
}

@MainActor
private func pinch(_ grid: SwiftGridView, to scale: CGFloat, at location: CGPoint = .zero) {
    pinch(grid, through: [scale], at: location)
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

        pinch(grid, to: 2.0)
        #expect(grid.zoomScale == 2.0)
        #expect(fixture.contentSize.width == originalWidth * 2)

        // A fresh gesture reports `scale` from 1 again; the grid must build on
        // the zoom it already has rather than resetting to it.
        pinch(grid, to: 2.0)
        #expect(grid.zoomScale == 4.0)
        #expect(fixture.contentSize.width == originalWidth * 4)
    }

    /// Regression for zoom sticking on device: with stops configured, the small
    /// per-event deltas of a slow pinch were discarded whenever snapping rounded
    /// back to the current stop, so the zoom could never leave it.
    @Test func aSlowPinchStillReachesTheNextStop() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomStops = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
        grid.zoomSpeed = 0.5

        // Many small steps, none of which alone spans the gap to the next stop.
        let steps = stride(from: 1.02, through: 1.60, by: 0.02).map { CGFloat($0) }
        pinch(grid, through: steps)

        #expect(grid.zoomScale == 1.25)
    }

    /// The same, pinching back down out of the minimum.
    @Test func aSlowPinchEscapesTheMinimumZoom() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.minimumZoomScale = 0.75
        grid.zoomStops = [0.75, 1.0, 1.25, 1.5]
        grid.zoomScale = 0.75

        let steps = stride(from: 1.02, through: 1.50, by: 0.02).map { CGFloat($0) }
        pinch(grid, through: steps)

        #expect(grid.zoomScale > 0.75)
    }

    /// Within one gesture the scale maps onto the zoom once; it must not compound
    /// per event, which would make a slow pinch zoom further than a fast one.
    @Test func oneGestureAppliesItsScaleOnlyOnce() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        pinch(grid, through: [1.2, 1.5, 1.8, 2.0])

        #expect(grid.zoomScale == 2.0)
    }

    @Test func pinchesWithMoreThanTwoTouchesStillZoom() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        grid.handlePinchGesture(StubPinchGestureRecognizer(state: .began))
        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 2.0, state: .changed, touches: 3))

        #expect(grid.zoomScale == 2.0)
    }

    @Test func pinchingBeyondTheLimitsClampsInsteadOfStopping() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        pinch(grid, to: 20.0)
        #expect(grid.zoomScale == grid.maximumZoomScale)

        pinch(grid, to: 0.001)
        #expect(grid.zoomScale == grid.minimumZoomScale)
    }

    @Test func zoomLimitsAreConfigurable() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.minimumZoomScale = 0.75
        grid.maximumZoomScale = 2.0

        pinch(grid, to: 10.0)
        #expect(grid.zoomScale == 2.0)

        pinch(grid, to: 0.01)
        #expect(grid.zoomScale == 0.75)
    }

    @Test func zoomSpeedDampensTheGesture() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomSpeed = 0.5

        // Half speed applies the gesture as its square root: a 4x pinch is a 2x zoom.
        pinch(grid, to: 4.0)

        #expect(grid.zoomScale == 2.0)
    }

    @Test func zoomSnapsToConfiguredStops() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomStops = [0.75, 1.0, 1.5, 2.0]

        pinch(grid, to: 1.8)
        #expect(grid.zoomScale == 2.0)

        grid.zoomScale = 1.0
        pinch(grid, to: 1.3)
        #expect(grid.zoomScale == 1.5)
    }

    @Test func stopsOutsideTheZoomRangeAreIgnored() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.maximumZoomScale = 2.0
        grid.zoomStops = [1.0, 2.0, 8.0]

        pinch(grid, to: 10.0)

        #expect(grid.zoomScale == 2.0)
    }

    @Test func aLiftedFingerDoesNotChangeTheZoom() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        grid.handlePinchGesture(StubPinchGestureRecognizer(state: .began))
        grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 2.0, state: .changed, touches: 1))

        #expect(grid.zoomScale == 1.0)
    }

    @Test func zoomAnchorsOnThePinchCentroid() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.setContentOffset(CGPoint(x: 100, y: 0), animated: false)
        grid.layoutIfNeeded()

        // Content point 200 sits 100pt into the viewport; at 2x it moves to 400,
        // so the offset has to follow it to 300 to keep it under the fingers.
        pinch(grid, to: 2.0, at: CGPoint(x: 200, y: 0))

        #expect(grid.collectionView.contentOffset.x == 300)
    }

    @Test func anchoredOffsetsStayWithinTheContent() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        // Anchoring at the far edge would push the offset past the content.
        pinch(grid, to: 5.0, at: CGPoint(x: 600, y: 0))

        let maxX = fixture.contentSize.width - grid.collectionView.bounds.width
        #expect(grid.collectionView.contentOffset.x >= 0)
        #expect(grid.collectionView.contentOffset.x <= maxX)
    }

    /// A horizontal zoom cannot change any height, so rebuilding the content
    /// height row by row on every gesture event is pure cost.
    @Test func aHorizontalZoomReusesTheCachedHeight() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        let beforeHorizontal = fixture.delegate.rowHeightCallCount
        grid.zoomScale = 2.0
        let horizontalCalls = fixture.delegate.rowHeightCallCount - beforeHorizontal

        grid.zoomAxis = .both
        let beforeVertical = fixture.delegate.rowHeightCallCount
        grid.zoomScale = 3.0
        let verticalCalls = fixture.delegate.rowHeightCallCount - beforeVertical

        #expect(horizontalCalls == 0, "a horizontal zoom must reuse the cached height")
        #expect(verticalCalls > 0, "a vertical zoom has to rebuild it")
    }

    /// Damping used to be linear on the difference from 1, which floored a
    /// pinch in at `start * (1 - zoomSpeed)` while leaving pinching out
    /// unbounded, putting the low end of the range out of reach.
    @Test func dampingReachesBothEndsOfTheRange() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.minimumZoomScale = 0.75
        grid.maximumZoomScale = 2.0
        grid.zoomSpeed = 0.5

        pinch(grid, to: 100.0)
        #expect(grid.zoomScale == 2.0)

        // From the top of the range, one pinch in must still reach the bottom.
        pinch(grid, to: 0.001)
        #expect(grid.zoomScale == 0.75)
    }

    @Test func dampingIsSymmetricAboutIdentity() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomSpeed = 0.5

        pinch(grid, to: 4.0)
        #expect(grid.zoomScale == 2.0)

        // The reciprocal gesture undoes it exactly.
        pinch(grid, to: 0.25)
        #expect(grid.zoomScale == 1.0)
    }

    /// The anchored offset is bounded by the scroll view, which a content inset
    /// moves: clamping to zero would jerk the content by the inset.
    @Test func anchoringRespectsTheContentInset() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.collectionView.contentInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
        grid.setContentOffset(CGPoint(x: -40, y: 0), animated: false)
        grid.layoutIfNeeded()

        pinch(grid, to: 2.0, at: CGPoint(x: 0, y: 0))

        #expect(grid.collectionView.contentOffset.x == -40)
    }

    /// Only the axes the zoom moved may be bounded.
    @Test func aHorizontalZoomLeavesTheVerticalOffsetAlone() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomAxis = .horizontal
        grid.collectionView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        grid.setContentOffset(CGPoint(x: 0, y: -60), animated: false)
        grid.layoutIfNeeded()

        pinch(grid, to: 2.0, at: CGPoint(x: 100, y: 100))

        #expect(grid.collectionView.contentOffset.y == -60)
    }

    /// A reload moves the zoom out from under a pinch in flight. The fingers have
    /// already moved by then, so their travel must be measured from the reload
    /// rather than from where the gesture began.
    @Test func aReloadMidPinchDoesNotStepTheZoom() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomScale = 2.0

        let recognizer = StubPinchGestureRecognizer(state: .began)
        grid.handlePinchGesture(recognizer)

        recognizer.stubState = .changed
        recognizer.fingerScale = 1.5
        grid.handlePinchGesture(recognizer)
        #expect(grid.zoomScale == 3.0)

        grid.reloadData()
        grid.layoutIfNeeded()
        #expect(grid.zoomScale == 1.0)

        // Fingers held still across the reload: the zoom must hold still too.
        grid.handlePinchGesture(recognizer)
        #expect(grid.zoomScale == 1.0, "a stationary pinch must not move the zoom after a reload")

        // And carry on from there rather than from the original start.
        recognizer.fingerScale = 3.0
        grid.handlePinchGesture(recognizer)
        #expect(grid.zoomScale == 2.0, "further travel measures from the reload")
    }

    /// The same correction covers a host moving the zoom during a pinch.
    @Test func aProgrammaticZoomMidPinchIsMeasuredFrom() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid

        let recognizer = StubPinchGestureRecognizer(state: .began)
        grid.handlePinchGesture(recognizer)

        recognizer.stubState = .changed
        recognizer.fingerScale = 2.0
        grid.handlePinchGesture(recognizer)
        #expect(grid.zoomScale == 2.0)

        grid.zoomScale = 1.0

        grid.handlePinchGesture(recognizer)
        #expect(grid.zoomScale == 1.0, "a stationary pinch must not undo the host's change")
    }

    /// Configuring a grid before its dataSource must not lay it out.
    @Test func limitsCanBeSetBeforeTheDataSource() {
        let grid = SwiftGridView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))

        grid.minimumZoomScale = 1.5
        grid.maximumZoomScale = 3.0

        #expect(grid.minimumZoomScale == 1.5)
        #expect(grid.maximumZoomScale == 3.0)
    }

    @Test func narrowingTheLimitsBringsTheZoomBackInRange() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomScale = 4.0

        grid.maximumZoomScale = 2.0
        #expect(grid.zoomScale == 2.0)

        grid.zoomScale = 0.5
        grid.minimumZoomScale = 1.0
        #expect(grid.zoomScale == 1.0)
        #expect(fixture.delegate.scales(for: "zoomDidChange") == [4.0, 2.0, 0.5, 1.0])
    }

    @Test func twoFingerTapResetsTheZoom() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let originalWidth = fixture.contentSize.width

        pinch(grid, to: 3.0)
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

        pinch(grid, to: 2.0, at: CGPoint(x: 200, y: 200))

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

    /// Reported from the example app: after zooming, switching the axis left the
    /// headers and footers at the old size while the cells took the new one.
    /// Zoomed measurements are rounded to whole points, deliberately: fractional
    /// frames put text and cell seams off the pixel grid. Every other zoom test
    /// uses an integral scale, where rounding is invisible, so this is the only
    /// thing pinning that choice.
    @Test func zoomedFramesLandOnWholePoints() throws {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let layout = grid.collectionView.collectionViewLayout
        let path = IndexPath(item: 0, section: 0)

        grid.zoomAxis = .both
        grid.zoomScale = 1.337

        let frame = try #require(layout.layoutAttributesForItem(at: path)).frame

        // 100pt column and 50pt row from the fixture's delegate.
        #expect(frame.width == 134, "round(100 * 1.337)")
        #expect(frame.height == 67, "round(50 * 1.337)")
    }

    @Test func changingTheAxisResizesCellsAndSupplementaryViewsTogether() throws {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let layout = grid.collectionView.collectionViewLayout
        let path = IndexPath(item: 0, section: 0)

        func heights() throws -> (cell: CGFloat, header: CGFloat, footer: CGFloat, sectionHeader: CGFloat) {
            (
                try #require(layout.layoutAttributesForItem(at: path)).frame.height,
                try #require(layout.layoutAttributesForSupplementaryView(ofKind: SwiftGridElementKindHeader, at: path)).frame.height,
                try #require(layout.layoutAttributesForSupplementaryView(ofKind: SwiftGridElementKindFooter, at: path)).frame.height,
                try #require(layout.layoutAttributesForSupplementaryView(ofKind: SwiftGridElementKindSectionHeader, at: path)).frame.height
            )
        }

        let base = try heights()

        grid.zoomAxis = .both
        grid.zoomScale = 2.0
        let zoomed = try heights()
        #expect(zoomed.cell == base.cell * 2)
        #expect(zoomed.header == base.header * 2)
        #expect(zoomed.footer == base.footer * 2)
        #expect(zoomed.sectionHeader == base.sectionHeader * 2)

        // Back to a horizontal axis: every kind must return to its base height
        // together, not just the cells.
        grid.zoomAxis = .horizontal
        let restored = try heights()
        #expect(restored.cell == base.cell)
        #expect(restored.header == base.header)
        #expect(restored.footer == base.footer)
        #expect(restored.sectionHeader == base.sectionHeader)
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

    /// reloadData resets the layout's zoom, which a host scaling its own cell
    /// content needs to hear about.
    @Test func reloadingDataReportsTheZoomReset() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.zoomScale = 2.0

        grid.reloadData()
        grid.layoutIfNeeded()

        #expect(grid.zoomScale == 1.0)
        #expect(fixture.delegate.scales(for: "zoomDidChange") == [2.0, 1.0])
    }

    @Test func reloadingDataAtIdentityDoesNotNotify() {
        let fixture = makeZoomFixture()

        fixture.grid.reloadData()

        #expect(fixture.delegate.scales(for: "zoomDidChange").isEmpty)
    }

    @Test func unchangedPinchesDoNotNotifyTheDelegate() {
        let fixture = makeZoomFixture()

        fixture.grid.handlePinchGesture(StubPinchGestureRecognizer(state: .began))
        fixture.grid.handlePinchGesture(StubPinchGestureRecognizer(scale: 1.0, state: .changed))

        #expect(fixture.delegate.scales(for: "zoomDidChange").isEmpty)
    }
}

// MARK: - Selection During a Zoom

/// A pinch is easy to land a stray third finger in, which would otherwise select
/// whatever it came down on.
@MainActor
@Suite struct SwiftGridViewZoomSelectionTests {

    private func beginPinch(_ grid: SwiftGridView) -> StubPinchGestureRecognizer {
        let recognizer = StubPinchGestureRecognizer(state: .began)
        grid.handlePinchGesture(recognizer)

        return recognizer
    }

    @Test func cellsAreNotSelectableWhilePinching() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let itemPath = IndexPath(item: 0, section: 0)

        #expect(grid.collectionView(grid.collectionView, shouldSelectItemAt: itemPath))

        let recognizer = beginPinch(grid)
        #expect(!grid.collectionView(grid.collectionView, shouldSelectItemAt: itemPath))
        #expect(!grid.collectionView(grid.collectionView, shouldHighlightItemAt: itemPath))

        recognizer.stubState = .ended
        grid.handlePinchGesture(recognizer)

        #expect(grid.collectionView(grid.collectionView, shouldSelectItemAt: itemPath))
    }

    @Test func aCancelledPinchRestoresSelection() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let itemPath = IndexPath(item: 0, section: 0)

        let recognizer = beginPinch(grid)
        recognizer.stubState = .cancelled
        grid.handlePinchGesture(recognizer)

        #expect(grid.collectionView(grid.collectionView, shouldSelectItemAt: itemPath))
    }

    /// A reusable view toggles itself before telling the grid, so refusing the
    /// change has to put the view back rather than just ignore it.
    @Test func aStrayTouchOnAHeaderIsRefusedAndLeavesNoTrace() throws {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        let header = try #require(grid.supplementaryView(ofElementKind: SwiftGridElementKindSectionHeader, at: indexPath))

        _ = beginPinch(grid)

        header.touchesBegan([], with: nil)
        header.touchesEnded([], with: nil)

        #expect(!header.selected, "the view must not be left looking selected")
        #expect(!header.highlighted)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader).isEmpty)
        #expect(fixture.delegate.indexPaths(for: "didSelectSectionHeader").isEmpty)
    }

    /// Selection made before the pinch survives it.
    @Test func aPinchDoesNotClearAnExistingSelection() throws {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        grid.selectHeaderAtIndexPath(indexPath)

        let header = try #require(grid.supplementaryView(ofElementKind: SwiftGridElementKindHeader, at: indexPath))
        header.selected = true

        _ = beginPinch(grid)
        header.touchesBegan([], with: nil)
        header.touchesEnded([], with: nil)

        #expect(header.selected, "the view goes back to what the grid holds, not to unselected")
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindHeader) == [indexPath])
    }

    @Test func selectionDuringZoomCanBeAllowed() throws {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        grid.allowsSelectionDuringZoom = true
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)
        let header = try #require(grid.supplementaryView(ofElementKind: SwiftGridElementKindSectionHeader, at: indexPath))

        _ = beginPinch(grid)

        #expect(grid.collectionView(grid.collectionView, shouldSelectItemAt: IndexPath(item: 0, section: 0)))

        header.touchesBegan([], with: nil)
        header.touchesEnded([], with: nil)

        #expect(header.selected)
        #expect(grid.selectedIndexPathsForSupplementaryView(ofElementKind: SwiftGridElementKindSectionHeader) == [indexPath])
    }

    /// Programmatic selection is not a stray finger.
    @Test func programmaticSelectionStillWorksWhilePinching() {
        let fixture = makeZoomFixture()
        let grid = fixture.grid
        let indexPath = IndexPath(forSGRow: 0, atColumn: 0, inSection: 0)

        _ = beginPinch(grid)
        grid.selectCellAtIndexPath(indexPath, animated: false)

        #expect(grid.indexPathsForSelectedItems == [indexPath])
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
