// SwiftGridViewTests.swift
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

import XCTest
@testable import SwiftGridView

class SwiftGridViewTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    
    // MARK: - SwiftGridCell
    
    func testSwiftGridCell() {
        XCTAssert(SwiftGridCell.reuseIdentifier() == "SwiftGridCellReuseId")
        
        let rect:CGRect = CGRect(x: 0, y: 0, width: 125, height: 35)
        let cell:SwiftGridCell = SwiftGridCell(frame: rect)
        
        XCTAssert(cell.frame.equalTo(rect))
        XCTAssert(cell.backgroundColor == UIColor.clear)
        
        //SwiftGridTestNibCell.xib
    }
    
    
    // MARK: - SwiftGridReusableView
    
    func testSwiftGridReusableView() {
        XCTAssert(SwiftGridReusableView.reuseIdentifier() == "SwiftGridReusableViewReuseId")
        
        let rect:CGRect = CGRect(x: 0, y: 0, width: 125, height: 35)
        let view:SwiftGridReusableView = SwiftGridReusableView(frame: rect)
        let redView = UIView()
        redView.backgroundColor = UIColor.red
        view.backgroundView = redView
        let blueView = UIView()
        blueView.backgroundColor = UIColor.blue
        view.selectedBackgroundView = blueView
        
        view.layoutIfNeeded()
        
        XCTAssert(view.frame.equalTo(rect))
        XCTAssert(view.contentView.frame.equalTo(rect))
        XCTAssert(view.backgroundView!.frame.equalTo(rect))
        XCTAssert(view.selectedBackgroundView!.frame.equalTo(rect))
        XCTAssert(view.backgroundColor == UIColor.clear)
        
        view.highlighted = true
        XCTAssert(view.selectedBackgroundView?.isHidden == false)
        view.highlighted = false
        XCTAssert(view.selectedBackgroundView?.isHidden == true)
        view.selected = true
        XCTAssert(view.selectedBackgroundView?.isHidden == false)
        view.selected = false
        XCTAssert(view.selectedBackgroundView?.isHidden == true)
        
        let greenView = UIView()
        greenView.backgroundColor = UIColor.green
        view.backgroundView = greenView
        
        // Verify that the Background is behind the Selected Background
        XCTAssert(view.subviews.firstIndex(of: view.backgroundView!)! < view.subviews.firstIndex(of: view.selectedBackgroundView!)!)
        
        
        view.prepareForReuse()
        XCTAssert(view.highlighted == false)
        XCTAssert(view.selected == false)
        XCTAssert(view.selectedBackgroundView?.isHidden == true)
    }
    
    
    // MARK: - IndexPath+SwiftGridView
    
    func testIndexPathExtension() {
        let indexPath: IndexPath = IndexPath(forSGRow: 3, atColumn: 4, inSection: 2)
        
        XCTAssertEqual(indexPath.sgRow, 3)
        XCTAssertEqual(indexPath.sgColumn, 4)
        XCTAssertEqual(indexPath.sgSection, 2)
    }
    
}
