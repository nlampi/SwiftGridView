// PrettyDelegate.swift
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

protocol PrettyDelegateProtocol : AnyObject {
    func dataGridView(_ dataGridView: SwiftGridView, didSelectHeaderAtIndexPath indexPath: IndexPath)
}


class PrettyDelegate : SwiftGridViewDelegate {
    
    weak var delegate:PrettyDelegateProtocol?
    
    func dataGridView(_ dataGridView: SwiftGridView, widthOfColumnAtIndex columnIndex: Int) -> CGFloat {
        var returnValue:CGFloat
        
        switch columnIndex {
        case 0:
            returnValue = 260.0
        case 1:
            returnValue = 200.0
        case 2:
            returnValue = 140.0
        case 3:
            returnValue = 120.0
        case 5:
            returnValue = 150.0
        case 6:
            returnValue = 120.0
        default:
            returnValue = 100.0
        }
        
        return returnValue
    }
    
    func dataGridView(_ dataGridView: SwiftGridView, heightOfRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        
        return 45.0
    }
    
    func heightForGridHeaderInDataGridView(_ dataGridView: SwiftGridView) -> CGFloat {
        
        return 70.0
    }
    
    
    func dataGridView(_ dataGridView: SwiftGridView, didSelectHeaderAtIndexPath indexPath: IndexPath) {
        self.delegate?.dataGridView(dataGridView, didSelectHeaderAtIndexPath: indexPath)
    }
}
