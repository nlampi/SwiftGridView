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

struct PrettyDataPoint {
    var title:String
    var alignment:NSTextAlignment = .left
    var order:PrettyHeaderSortOrder = .none
}

class PrettyDataSource : SwiftGridViewDataSource {
    
    var headers = [PrettyDataPoint]()
    var sortingColumn = 4
    var countries = [PECountry]()
    
    init() {
        // Init Header Data
        headers.append(PrettyDataPoint(title: "Country", alignment: .left, order: .none))
        headers.append(PrettyDataPoint(title: "Capital", alignment: .left, order: .none))
        headers.append(PrettyDataPoint(title: "Currency", alignment: .left, order: .none))
        headers.append(PrettyDataPoint(title: "Phone", alignment: .left, order: .none))
        headers.append(PrettyDataPoint(title: "TLD", alignment: .left, order: .ascending))
        headers.append(PrettyDataPoint(title: "Population", alignment: .right, order: .none))
        headers.append(PrettyDataPoint(title: "Area", alignment: .right, order: .none))
        
        // Init Row Data
        let plistFile = Bundle.main.path(forResource: "countries", ofType: "plist")!
        let countriesData = NSArray(contentsOfFile: plistFile)!
        
        for countryDetails in countriesData as! [[String:Any]] {
            self.countries.append(PECountry(dictionary: countryDetails))
        }
    }
    
    
    // MARK: - Public Methods
    
    func sortDisplayString() -> String {
        let orderString = headers[sortingColumn].order == .ascending ? "Ascending" : "Descending"
        
        return "By \(headers[sortingColumn].title) \(orderString)"
    }
    
    func sortUsing(_ dataGridView: SwiftGridView, column:NSInteger) {
        // Set new Sorting
        switch headers[column].order {
        case .ascending:
            headers[column].order = .descending
        case .descending:
            headers[column].order = .ascending
        case .none:
            headers[column].order = .ascending
        }
        
        if column != sortingColumn {
            // Reset Old Column
            headers[sortingColumn].order = .none
        }
        
        sortingColumn = column
        
        sortCountryData()
        dataGridView.reloadData()
    }
    
    
    // MARK: - Private Data Methods
    
    /// Quick and Dirty Sorting
    func sortCountryData() {
        if headers[sortingColumn].order == .ascending {
            switch sortingColumn {
            case 0:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.name < country2.name
                }
            case 1:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.capital < country2.capital
                }
            case 2:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.currency < country2.currency
                }
            case 3:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.phone < country2.phone
                }
            case 4:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.tld < country2.tld
                }
            case 5:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.population < country2.population
                }
            case 6:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.area < country2.area
                }
            default:
                print("ERROR: Unknown Sort Column")
            }
        } else {
            switch sortingColumn {
            case 0:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.name > country2.name
                }
            case 1:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.capital > country2.capital
                }
            case 2:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.currency > country2.currency
                }
            case 3:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.phone > country2.phone
                }
            case 4:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.tld > country2.tld
                }
            case 5:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.population > country2.population
                }
            case 6:
                self.countries.sort { (country1, country2) -> Bool in
                    country1.area > country2.area
                }
            default:
                print("ERROR: Unknown Sort Column")
            }
        }
    }
    
    
    // MARK: - SwiftGridViewDataSource Methods
    
    func numberOfSectionsInDataGridView(_ dataGridView: SwiftGridView) -> Int {
        
        return 1
    }
    
    func numberOfColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int {
        
        return self.headers.count
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
        
        headerView.configureFor(dataPoint: self.headers[column])
        
        return headerView
    }
    
}
