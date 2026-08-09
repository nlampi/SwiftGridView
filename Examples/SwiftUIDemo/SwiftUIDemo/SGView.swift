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
            cell.configureFor("\(country.name)", and: header)
        case 1:
            cell.configureFor("\(country.capital)", and: header)
        case 2:
            cell.configureFor("\(country.currency)", and: header)
        case 3:
            cell.configureFor("\(country.phone)", and: header)
        case 4:
            cell.configureFor("\(country.tld)", and: header)
        case 5:
            if country.population < 0 {
                cell.configureFor("-", and: header)
            } else {
                cell.configureFor("\(country.population)", and: header)
            }
        case 6:
            if country.area < 0 {
                cell.configureFor("-", and: header)
            } else {
                cell.configureFor("\(country.area)", and: header)
            }
        default:
            cell.configureFor("-", and: header)
        }

        return cell
    }

    func dataGridView(_ dataGridView: SwiftGridView, gridHeaderViewForColumn column: Int) -> SwiftGridReusableView {
        let headerView = dataGridView.dequeueReusableSupplementaryViewOfKind(SwiftGridElementKindHeader, withReuseIdentifier: DemoView.reuseIdentifier(), atColumn: column) as! DemoView

        headerView.configureFor(self.headers[column])

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
}

/// Uses the library's `SwiftGrid` SwiftUI wrapper directly.
struct SGView: View {

    @StateObject private var model = DemoGridModel()

    var body: some View {
        SwiftGrid(dataSource: model, delegate: model) { gridView in
            // Register Cells/Views
            gridView.register(DemoView.self, forSupplementaryViewOfKind: SwiftGridElementKindHeader, withReuseIdentifier: DemoView.reuseIdentifier())
            gridView.register(DemoCell.self, forCellWithReuseIdentifier: DemoCell.reuseIdentifier())
        }
    }
}
