//
// SGView.swift
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
import SwiftGridView

struct DemoColumn {
    var title:String
    var width:CGFloat
    var alignment:Alignment = .leading
}

/// Provides the grid content, exactly like a UIKit datasource/delegate would.
@MainActor
final class DemoGridModel: ObservableObject, SwiftGridViewDataSource, SwiftGridViewDelegate {

    var headers = [DemoColumn]()
    var countries = [Country]()

    /// Bound to the picker in `SGView` and pushed onto the grid from the
    /// `update` closure. Published, so changing it re-runs the SwiftUI update
    /// that applies it.
    @Published var zoomAxis: SwiftGridZoomAxis = .both {
        didSet {
            self.refreshTextScale()
        }
    }

    /// Scale applied to cell text. Only a zoom that grows the rows should grow
    /// the text, so this follows the axis as well as the zoom scale.
    private(set) var textScale: CGFloat = 1.0
    private var zoomScale: CGFloat = 1.0
    /// Set from the `update` closure. Weak: the grid is owned by SwiftUI.
    private weak var gridView: SwiftGridView?

    func adopt(_ gridView: SwiftGridView) {
        self.gridView = gridView
    }

    init() {
        // Init Header Data
        self.headers.append(DemoColumn(title: "Country", width: 150, alignment: .leading))
        self.headers.append(DemoColumn(title: "Capital", width: 150, alignment: .leading))
        self.headers.append(DemoColumn(title: "Currency", width: 140, alignment: .leading))
        self.headers.append(DemoColumn(title: "Phone", width: 120, alignment: .center))
        self.headers.append(DemoColumn(title: "TLD", width: 150, alignment: .leading))
        self.headers.append(DemoColumn(title: "Population", width: 120, alignment: .trailing))
        self.headers.append(DemoColumn(title: "Area", width: 100, alignment: .trailing))

        // Init Row Data
        let plistFile = Bundle.main.path(forResource: "countries", ofType: "plist")!
        let countriesData = NSArray(contentsOfFile: plistFile)!

        for countryDetails in countriesData as! [[String:Any]] {
            self.countries.append(Country(dictionary: countryDetails))
        }
    }


    // MARK: - SwiftGridViewDataSource Methods

    func numberOfSectionsInDataGridView(_ dataGridView: SwiftGridView) -> Int {

        1
    }

    func numberOfColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int {

        self.headers.count
    }

    func numberOfFrozenColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int {

        1
    }

    func dataGridView(_ dataGridView: SwiftGridView, numberOfRowsInSection section: Int) -> Int {

        self.countries.count
    }

    func dataGridView(_ dataGridView: SwiftGridView, cellAtIndexPath indexPath: IndexPath) -> SwiftGridCell {
        let header = self.headers[indexPath.sgColumn]
        let country = self.countries[indexPath.sgRow]
        let cell = dataGridView.dequeueReusableCellWithReuseIdentifier(DemoCell.reuseIdentifier(), forIndexPath: indexPath) as! DemoCell

        switch indexPath.sgColumn {
        case 0:
            cell.configureFor("\(country.name)", and: header, textScale: self.textScale)
        case 1:
            cell.configureFor("\(country.capital)", and: header, textScale: self.textScale)
        case 2:
            cell.configureFor("\(country.currency)", and: header, textScale: self.textScale)
        case 3:
            cell.configureFor("\(country.phone)", and: header, textScale: self.textScale)
        case 4:
            cell.configureFor("\(country.tld)", and: header, textScale: self.textScale)
        case 5:
            if country.population < 0 {
                cell.configureFor("-", and: header, textScale: self.textScale)
            } else {
                cell.configureFor("\(country.population)", and: header, textScale: self.textScale)
            }
        case 6:
            if country.area < 0 {
                cell.configureFor("-", and: header, textScale: self.textScale)
            } else {
                cell.configureFor("\(country.area)", and: header, textScale: self.textScale)
            }
        default:
            cell.configureFor("-", and: header, textScale: self.textScale)
        }

        return cell
    }

    func dataGridView(_ dataGridView: SwiftGridView, gridHeaderViewForColumn column: Int) -> SwiftGridReusableView {
        let headerView = dataGridView.dequeueReusableSupplementaryViewOfKind(SwiftGridElementKindHeader, withReuseIdentifier: DemoView.reuseIdentifier(), atColumn: column) as! DemoView

        headerView.configureFor(self.headers[column], textScale: self.textScale)

        return headerView
    }


    // MARK: - SwiftGridViewDelegate Methods

    func dataGridView(_ dataGridView: SwiftGridView, widthOfColumnAtIndex columnIndex: Int) -> CGFloat {

        self.headers[columnIndex].width
    }

    func dataGridView(_ dataGridView: SwiftGridView, heightOfRowAtIndexPath indexPath: IndexPath) -> CGFloat {

        45
    }

    func heightForGridHeaderInDataGridView(_ dataGridView: SwiftGridView) -> CGFloat {

        70
    }

    func dataGridView(_ dataGridView: SwiftGridView, didChangeZoomScale zoomScale: CGFloat) {
        self.zoomScale = zoomScale
        self.refreshTextScale()
    }


    // MARK: - Zoom Content Scaling

    /// Recomputes the text scale and pushes it into the views already on screen.
    /// Called for a zoom change and for an axis change, which does not report a
    /// zoom change because the scale itself has not moved.
    private func refreshTextScale() {
        let updated = self.zoomAxis.scalesVertically ? self.zoomScale : 1.0

        guard updated != self.textScale else {

            return
        }

        self.textScale = updated
        self.rescaleVisibleContent()
    }

    /// The grid holds the views, so the host reaches them through it. Cells
    /// dequeued later pick the scale up in `cellAtIndexPath`.
    private func rescaleVisibleContent() {
        guard let gridView = self.gridView else {

            return
        }

        for case let cell as DemoCell in gridView.visibleCells {
            cell.applyTextScale(self.textScale)
        }

        for case let view as DemoView in gridView.collectionView.visibleSupplementaryViews(ofKind: SwiftGridElementKindHeader) {
            view.applyTextScale(self.textScale)
        }
    }
}

/// Uses the library's `SwiftGrid` SwiftUI wrapper directly.
struct SGView: View {

    @StateObject private var model = DemoGridModel()

    var body: some View {
        VStack(spacing: 8) {
            // Pinch the grid to zoom, two finger tap to reset. The picker drives
            // the grid purely through SwiftUI state.
            HStack(spacing: 8) {
                Spacer()

                Text("Zoom axis")
                    .font(.caption)
                    .foregroundColor(.white)

                Picker("Zoom axis", selection: $model.zoomAxis) {
                    Text("Horizontal").tag(SwiftGridZoomAxis.horizontal)
                    Text("Vertical").tag(SwiftGridZoomAxis.vertical)
                    Text("Both").tag(SwiftGridZoomAxis.both)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 230)
            }
            .padding(.horizontal, 10)

            SwiftGrid(dataSource: model, delegate: model) { gridView in
                // Runs once: register cells and reusable views.
                gridView.register(DemoView.self, forSupplementaryViewOfKind: SwiftGridElementKindHeader, withReuseIdentifier: DemoView.reuseIdentifier())
                gridView.register(DemoCell.self, forCellWithReuseIdentifier: DemoCell.reuseIdentifier())
            } update: { gridView in
                // Runs on every SwiftUI update: assign properties driven by
                // state. Assignments only, and writing the same value again
                // does nothing, so repeating this is free.
                gridView.pinchExpandEnabled = true
                gridView.zoomAxis = model.zoomAxis
                gridView.minimumZoomScale = 0.75
                gridView.maximumZoomScale = 2.0
                gridView.zoomSpeed = 0.5

                model.adopt(gridView)
            }
        }
    }
}
