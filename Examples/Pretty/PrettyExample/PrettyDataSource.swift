// PrettyDataSource.swift
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

class PrettyDataSource : SwiftGridViewDataSource {
    
    var countries = [PECountry]()
    
    init() {
        let plistFile = Bundle.main.path(forResource: "countries", ofType: "plist")!
        let countriesData = NSArray(contentsOfFile: plistFile)!
        
        for countryDetails in countriesData as! [[String:Any]] {
            self.countries.append(PECountry(dictionary: countryDetails))
        }
    }
    
    func numberOfSectionsInDataGridView(_ dataGridView: SwiftGridView) -> Int {
        
        return 1
    }
    
    func numberOfColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int {
        
        return 7
    }
    
    func numberOfFrozenColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int {
        
        return 1
    }
    
    func dataGridView(_ dataGridView: SwiftGridView, numberOfRowsInSection section: Int) -> Int {
        
        return self.countries.count
    }
    
    func dataGridView(_ dataGridView: SwiftGridView, cellAtIndexPath indexPath: IndexPath) -> SwiftGridCell {
        let cell = dataGridView.dequeueReusableCellWithReuseIdentifier(PrettyRowCell.reuseIdentifier(), forIndexPath: indexPath) as! PrettyRowCell
        let country = self.countries[indexPath.sgRow]
        
        switch indexPath.sgColumn {
        case 0:
            cell.mainLabel.text = country.name
        case 1:
            cell.mainLabel.text = country.capital
        case 2:
            cell.mainLabel.text = country.currency
        case 3:
            cell.mainLabel.text = country.phone
        case 4:
            cell.mainLabel.text = country.tld
        case 5:
            if country.population < 0 {
                cell.mainLabel.text = "-"
            } else {
                cell.mainLabel.text = "\(country.population)"
            }
            cell.mainLabel.textAlignment = .right
        case 6:
            if country.area < 0 {
                cell.mainLabel.text = "-"
            } else {
                cell.mainLabel.text = "\(country.area)"
            }
            cell.mainLabel.textAlignment = .right
        default:
            cell.mainLabel.text = "-"
        }
        
        return cell
    }
    
    func dataGridView(_ dataGridView: SwiftGridView, gridHeaderViewForColumn column: NSInteger) -> SwiftGridReusableView {
        let headerView = dataGridView.dequeueReusableSupplementaryViewOfKind(SwiftGridElementKindHeader, withReuseIdentifier: PrettyHeaderView.reuseIdentifier(), atColumn: column) as! PrettyHeaderView
        
        switch column {
        case 0:
            headerView.mainLabel.text = "Country"
        case 1:
            headerView.mainLabel.text = "Capital"
        case 2:
            headerView.mainLabel.text = "Currency"
        case 3:
            headerView.mainLabel.text = "Phone"
        case 4:
            headerView.mainLabel.text = "TLD"
        case 5:
            headerView.mainLabel.text = "Population"
            headerView.mainLabel.textAlignment = .right
        case 6:
            headerView.mainLabel.text = "Area"
            headerView.mainLabel.textAlignment = .right
        default:
            headerView.mainLabel.text = "Unknown"
        }
        
        return headerView
    }
}
