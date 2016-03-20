// ViewController.swift
// Copyright (c) 2016 Nathan Lampi (http://nathanlampi.com/)
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

import UIKit
import SwiftGridView

class ViewController: UIViewController, SwiftGridViewDataSource, SwiftGridViewDelegate {
    
    @IBOutlet weak var dataGridView: SwiftGridView! /// Data Grid IBOutlet
    
    var sectionCount: Int = 5
    var frozenColumns: Int = 1
    var reloadOverride: Bool = false
    var columnCount: Int = 10
    var rowCountIncrease: Int = 90
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        self.dataGridView = SwiftGridView(frame: CGRect(x: 30, y: 30, width: 450, height: 500))
        //        self.view.addSubview(self.dataGridView)
        
        // Do any additional setup after loading the view, typically from a nib.
        self.dataGridView.delegate = self
        self.dataGridView.dataSource = self
        self.dataGridView.allowsSelection = true
        self.dataGridView.allowsMultipleSelection = true
        self.dataGridView.rowSelectionEnabled = true
        self.dataGridView.bounces = true
        self.dataGridView.stickySectionHeaders = true
        self.dataGridView.showsHorizontalScrollIndicator = true
        self.dataGridView.showsVerticalScrollIndicator = true
        self.dataGridView.alwaysBounceHorizontal = false
        self.dataGridView.alwaysBounceVertical = false
        self.dataGridView.pinchExpandEnabled = true
        
        self.dataGridView.registerClass(BasicTextCell.self, forCellWithReuseIdentifier:BasicTextCell.reuseIdentifier())
        self.dataGridView.registerClass(BasicTextReusableView.self, forSupplementaryViewOfKind: SwiftGridElementKindHeader, withReuseIdentifier: BasicTextReusableView.reuseIdentifier())
        self.dataGridView.registerClass(BasicTextReusableView.self, forSupplementaryViewOfKind: SwiftGridElementKindSectionHeader, withReuseIdentifier: BasicTextReusableView.reuseIdentifier())
        self.dataGridView.registerClass(BasicTextReusableView.self, forSupplementaryViewOfKind: SwiftGridElementKindSectionFooter, withReuseIdentifier: BasicTextReusableView.reuseIdentifier())
        self.dataGridView.registerClass(BasicTextReusableView.self, forSupplementaryViewOfKind: SwiftGridElementKindFooter, withReuseIdentifier: BasicTextReusableView.reuseIdentifier())
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Gesture Recognizers
    
    @IBAction func didTapChangeData(sender: AnyObject) {
        reloadOverride = false
        sectionCount = Int(arc4random_uniform(8)) + 1
        frozenColumns = Int(arc4random_uniform(4))
        columnCount = Int(arc4random_uniform(40)) + 1
        rowCountIncrease = Int(arc4random_uniform(90))
        
        self.dataGridView.reloadData()
    }
    
    @IBAction func didTapScrollButton(sender: AnyObject) {
        let indexPath = NSIndexPath(forSGRow: 0, atColumn: 0, inSection: 3)
        
        self.dataGridView.scrollToCellAtIndexPath(indexPath, atScrollPosition: [.Top, .Left], animated: true)
    }
    
    @IBAction func didTapReloadCells(sender: AnyObject) {
        self.reloadOverride = true
        
        // Reload Cells
        let indexPaths = [
            NSIndexPath(forSGRow: 0, atColumn: 0, inSection: 0),
            NSIndexPath(forSGRow: 0, atColumn: 2, inSection: 0),
            NSIndexPath(forSGRow: 1, atColumn: 1, inSection: 0),
            NSIndexPath(forSGRow: 1, atColumn: 3, inSection: 0)
        ]
        
        
        self.dataGridView.reloadCellsAtIndexPaths(indexPaths, animated: true, completion: { completed in
            self.reloadOverride = false
        })
        
        
        
        //        // Reload Headers
        //        indexPaths = [
        //            NSIndexPath(forsgRow: 0, atColumn: 1, inSection: 0),
        //            NSIndexPath(forsgRow: 0, atColumn: 3, inSection: 0)
        //        ]
        //        self.dataGridView.reloadSupplementaryViewsOfKind(SwiftGridElementKindHeader, atIndexPaths: indexPaths)
        //
        //        // Reload Section Headers
        //        indexPaths = [
        //            NSIndexPath(forsgRow: 0, atColumn: 1, inSection: 0),
        //            NSIndexPath(forsgRow: 0, atColumn: 3, inSection: 0)
        //        ]
        //        self.dataGridView.reloadSupplementaryViewsOfKind(SwiftGridElementKindSectionHeader, atIndexPaths: indexPaths)
        //
        //        // Reload Section Footers
        //        indexPaths = [
        //            NSIndexPath(forsgRow: 0, atColumn: 0, inSection: 0),
        //            NSIndexPath(forsgRow: 0, atColumn: 2, inSection: 0)
        //        ]
        //        self.dataGridView.reloadSupplementaryViewsOfKind(SwiftGridElementKindSectionFooter, atIndexPaths: indexPaths)
        //
        //
        //        // Reload Footers
        //        indexPaths = [
        //            NSIndexPath(forsgRow: 0, atColumn: 1, inSection: 0),
        //            NSIndexPath(forsgRow: 0, atColumn: 3, inSection: 0)
        //        ]
        //        self.dataGridView.reloadSupplementaryViewsOfKind(SwiftGridElementKindFooter, atIndexPaths: indexPaths)
    }
    
    
    // MARK: - SwiftGridViewDataSource
    
    func numberOfSectionsInDataGridView(dataGridView: SwiftGridView) -> Int {
        
        return sectionCount
    }
    
    func numberOfColumnsInDataGridView(dataGridView: SwiftGridView) -> Int {
        
        return columnCount
    }
    
    func dataGridView(dataGridView: SwiftGridView, numberOfRowsInSection section: Int) -> Int {
        
        return section + rowCountIncrease
    }
    
    // Cells
    func dataGridView(dataGridView: SwiftGridView, cellAtIndexPath indexPath: NSIndexPath) -> SwiftGridCell {
        let cell: BasicTextCell = dataGridView.dequeueReusableCellWithReuseIdentifier(BasicTextCell.reuseIdentifier(), forIndexPath: indexPath) as! BasicTextCell
        
        if(reloadOverride) {
            cell.backgroundView?.backgroundColor = UIColor.cyanColor()
        } else {
            let r: CGFloat = (60 + CGFloat(indexPath.sgSection) * 33) / 255
            let g: CGFloat = (60 + CGFloat(indexPath.sgRow) * 5) / 255
            let b: CGFloat = (190 + CGFloat(indexPath.sgColumn) * 5) / 255
            
            cell.backgroundView?.backgroundColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        }
        
        cell.textLabel.text = "(\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))"
        
        return cell
    }
    
    // Header / Footer Views
    func dataGridView(dataGridView: SwiftGridView, gridHeaderViewForColumn column: NSInteger) -> SwiftGridReusableView {
        let view = dataGridView.dequeueReusableSupplementaryViewOfKind(SwiftGridElementKindHeader, withReuseIdentifier: BasicTextReusableView.reuseIdentifier(), atColumn: column) as! BasicTextReusableView
        
        if(reloadOverride) {
            view.backgroundView?.backgroundColor = UIColor.cyanColor()
        } else {
            let r: CGFloat = (120 + CGFloat(column) * 5) / 255
            let g: CGFloat = (60 + CGFloat(column) * 5) / 255
            let b: CGFloat = (60 + CGFloat(column) * 5) / 255
            
            view.backgroundView?.backgroundColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        }
        
        view.textLabel.text = "HCol: (\(column))"
        
        return view
    }
    
    func dataGridView(dataGridView: SwiftGridView, gridFooterViewForColumn column: NSInteger) -> SwiftGridReusableView {
        let view = dataGridView.dequeueReusableSupplementaryViewOfKind(SwiftGridElementKindFooter, withReuseIdentifier: BasicTextReusableView.reuseIdentifier(), atColumn: column) as! BasicTextReusableView
        
        if(reloadOverride) {
            view.backgroundView?.backgroundColor = UIColor.cyanColor()
        } else {
            let r: CGFloat = (60 + CGFloat(column) * 5) / 255
            let g: CGFloat = (120 + CGFloat(column) * 5) / 255
            let b: CGFloat = (60 + CGFloat(column) * 5) / 255
            
            view.backgroundView?.backgroundColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        }
        
        view.textLabel.text = "FCol: (\(column))"
        
        return view
    }
    
    // Section Header / Footer Views
    func dataGridView(dataGridView: SwiftGridView, sectionHeaderCellAtIndexPath indexPath: NSIndexPath) -> SwiftGridReusableView {
        let view = dataGridView.dequeueReusableSupplementaryViewOfKind(SwiftGridElementKindSectionHeader, withReuseIdentifier: BasicTextReusableView.reuseIdentifier(), forIndexPath: indexPath) as! BasicTextReusableView
        
        if(reloadOverride) {
            view.backgroundView?.backgroundColor = UIColor.cyanColor()
        } else {
            let r: CGFloat = (190 + CGFloat(indexPath.sgSection) * 5) / 255
            let g: CGFloat = (190 + CGFloat(indexPath.sgRow) * 5) / 255
            let b: CGFloat = (60 + CGFloat(indexPath.sgColumn) * 5) / 255
            
            view.backgroundView?.backgroundColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        }
        
        view.textLabel.text = "(\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))"
        
        return view
    }
    
    func dataGridView(dataGridView: SwiftGridView, sectionFooterCellAtIndexPath indexPath: NSIndexPath) -> SwiftGridReusableView {
        let view = dataGridView.dequeueReusableSupplementaryViewOfKind(SwiftGridElementKindSectionFooter, withReuseIdentifier: BasicTextReusableView.reuseIdentifier(), forIndexPath: indexPath) as! BasicTextReusableView
        
        if(reloadOverride) {
            view.backgroundView?.backgroundColor = UIColor.cyanColor()
        } else {
            let r: CGFloat = (190 + CGFloat(indexPath.sgSection) * 5) / 255
            let g: CGFloat = (60 + CGFloat(indexPath.sgRow) * 5) / 255
            let b: CGFloat = (190 + CGFloat(indexPath.sgColumn) * 5) / 255
            
            view.backgroundView?.backgroundColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        }
        
        view.textLabel.text = "(\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))"
        
        return view
    }
    
    // Frozen Columns
    func numberOfFrozenColumnsInDataGridView(dataGridView: SwiftGridView) -> Int {
        
        return frozenColumns
    }
    
    
    // MARK: - SwiftGridViewDelegate
    
    func dataGridView(dataGridView: SwiftGridView, didSelectHeaderAtIndexPath indexPath: NSIndexPath) {
        
        NSLog("Selected header indexPath: (\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))")
    }
    func dataGridView(dataGridView: SwiftGridView, didDeselectHeaderAtIndexPath indexPath: NSIndexPath) {
        
        NSLog("Deselected header indexPath: (\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))")
    }
    
    func dataGridView(dataGridView: SwiftGridView, didSelectFooterAtIndexPath indexPath: NSIndexPath) {
        
        NSLog("Selected footer indexPath: (\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))")
    }
    
    func dataGridView(dataGridView: SwiftGridView, didDeselectFooterAtIndexPath indexPath: NSIndexPath) {
        
        NSLog("Deselected footer indexPath: (\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))")
    }
    
    func dataGridView(dataGridView: SwiftGridView, didSelectCellAtIndexPath indexPath: NSIndexPath) {
        
        NSLog("Selected indexPath: (\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))")
        
        //        dataGridView.deselectCellAtIndexPath(indexPath, animated: true)
    }
    
    func dataGridView(dataGridView: SwiftGridView, didDeselectCellAtIndexPath indexPath: NSIndexPath) {
        
        NSLog("Deselected indexPath: (\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))")
    }
    
    func dataGridView(dataGridView: SwiftGridView, didSelectSectionHeaderAtIndexPath indexPath: NSIndexPath) {
        
        NSLog("Selected section header indexPath: (\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))")
        
        //        dataGridView.deselectSectionHeaderAtIndexPath(indexPath)
    }
    
    func dataGridView(dataGridView: SwiftGridView, didDeselectSectionHeaderAtIndexPath indexPath: NSIndexPath) {
        
        NSLog("Deselected section header indexPath: (\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))")
    }
    
    func dataGridView(dataGridView: SwiftGridView, didSelectSectionFooterAtIndexPath indexPath: NSIndexPath) {
        
        NSLog("Selected section footer indexPath: (\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))")
        
        //        dataGridView.deselectSectionFooterAtIndexPath(indexPath)
    }
    
    func dataGridView(dataGridView: SwiftGridView, didDeselectSectionFooterAtIndexPath indexPath: NSIndexPath) {
        
        NSLog("Deselected section footer indexPath: (\(indexPath.sgSection), \(indexPath.sgColumn), \(indexPath.sgRow))")
    }
    
    func dataGridView(dataGridView: SwiftGridView, heightOfRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return 55
    }
    
    func dataGridView(dataGridView: SwiftGridView, widthOfColumnAtIndex columnIndex: Int) -> CGFloat {
        
        return 150 + 25 * CGFloat(columnIndex)
    }
    
    func heightForGridHeaderInDataGridView(dataGridView: SwiftGridView) -> CGFloat {
        
        return 75.0
    }
    
    func heightForGridFooterInDataGridView(dataGridView: SwiftGridView) -> CGFloat {
        
        return 55.0
    }
    
    func dataGridView(dataGridView: SwiftGridView, heightOfHeaderInSection section: Int) -> CGFloat {
        
        return 75.0
    }
    
    func dataGridView(dataGridView: SwiftGridView, heightOfFooterInSection section: Int) -> CGFloat {
        
        return 75.0
    }
}

