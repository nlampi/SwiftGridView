// IndexPath+SwiftGridView.swift
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


// MARK: - SwiftGridView Extensions

/**
 Swift Grid View Index Path Extension
 */
public extension IndexPath {
    /**
     Init Swift Grid View Index Path
     
     - Parameter row: Row for the data grid
     - Parameter column: Column for the data grid
     - Paramter section: Section for the data grid
     */
    init(forSGRow row: Int, atColumn column: Int, inSection section: Int) {
        let indexes: [Int] = [section, column, row]
        
        
        self.init(indexes: indexes)
    }
    
    /// Swift Grid View Section
    var sgSection: Int { get {
        
        return self[0]
        }
    }
    
    /// Swift Grid View Row
    var sgRow: Int { get {
        
        return self[2]
        }
    }
    
    /// Swift Grid View Column
    var sgColumn: Int { get {
        
        return self[1]
        }
    }
}
