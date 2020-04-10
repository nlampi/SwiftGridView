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

struct PrettyDataPoint {
    var title:String
    var width:CGFloat
    var alignment:Alignment = .leading
}

struct SGView: UIViewRepresentable {
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> SwiftGridView {
        let gridView = SwiftGridView()
        gridView.dataSource = context.coordinator
        gridView.delegate = context.coordinator
        
        // Register Cells/Views
        gridView.register(PrettyView.self, forSupplementaryViewOfKind: SwiftGridElementKindHeader, withReuseIdentifier: PrettyView.reuseIdentifier())
        gridView.register(PrettyCell.self, forCellWithReuseIdentifier: PrettyCell.reuseIdentifier())
        
        return gridView
    }
    
    func updateUIView(_ uiView: SwiftGridView, context: Context) {
        // Do Nothing?
    }
    
    class Coordinator: NSObject, SwiftGridViewDataSource, SwiftGridViewDelegate {
        
        var grid: SGView
        var headers = [PrettyDataPoint]()
        var countries = [PECountry]()
        
        init(_ swiftGridView: SGView) {
            self.grid = swiftGridView
            
            // Init Header Data
            self.headers.append(PrettyDataPoint(title: "Country", width: 150, alignment: .leading))
            self.headers.append(PrettyDataPoint(title: "Capital", width: 150, alignment: .leading))
            self.headers.append(PrettyDataPoint(title: "Currency", width: 140, alignment: .leading))
            self.headers.append(PrettyDataPoint(title: "Phone", width: 120, alignment: .center))
            self.headers.append(PrettyDataPoint(title: "TLD", width: 150, alignment: .leading))
            self.headers.append(PrettyDataPoint(title: "Population", width: 120, alignment: .trailing))
            self.headers.append(PrettyDataPoint(title: "Area", width: 100, alignment: .trailing))

            // Init Row Data
            let plistFile = Bundle.main.path(forResource: "countries", ofType: "plist")!
            let countriesData = NSArray(contentsOfFile: plistFile)!
            
            for countryDetails in countriesData as! [[String:Any]] {
                self.countries.append(PECountry(dictionary: countryDetails))
            }
        }
        
        
        // MARK - SwiftGridViewDataSource Methods
        
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
            let cell = dataGridView.dequeueReusableCellWithReuseIdentifier(PrettyCell.reuseIdentifier(), forIndexPath: indexPath) as! PrettyCell
            
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
        
        func dataGridView(_ dataGridView: SwiftGridView, gridHeaderViewForColumn column: NSInteger) -> SwiftGridReusableView {
            let headerView = dataGridView.dequeueReusableSupplementaryViewOfKind(SwiftGridElementKindHeader, withReuseIdentifier: PrettyView.reuseIdentifier(), atColumn: column) as! PrettyView
            
            headerView.configureFor(self.headers[column])
            
            return headerView
        }
        
        func dataGridView(_ dataGridView: SwiftGridView, widthOfColumnAtIndex columnIndex: Int) -> CGFloat {
            
            self.headers[columnIndex].width
        }
        
        
        // MARK - SwiftGridViewDelegate Methods
        
        func dataGridView(_ dataGridView: SwiftGridView, heightOfRowAtIndexPath indexPath: IndexPath) -> CGFloat {
            
            45
        }
        
        func heightForGridHeaderInDataGridView(_ dataGridView: SwiftGridView) -> CGFloat {
            
            70
        }
    }
}
