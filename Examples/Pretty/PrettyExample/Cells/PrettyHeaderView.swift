// PrettyHeaderView.swift
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

enum PrettyHeaderSortOrder {
    case none
    case ascending
    case descending
}


class PrettyHeaderView : SwiftGridReusableView {
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var sortingButton: UIButton!
    
    var sortOrder:PrettyHeaderSortOrder = .none
    
    override open class func reuseIdentifier() -> String {
        
        return "prettyHeaderViewReuseID"
    }
    
    
    // MARK: - Public Methods
    
    func configureFor(dataPoint:PrettyDataPoint) {
        self.mainLabel.text = dataPoint.title
        self.mainLabel.textAlignment = dataPoint.alignment
        self.sortOrder = dataPoint.order

        switch self.sortOrder {
        case .none:
            self.sortingButton.isHidden = true
        case .ascending:
            self.sortingButton.isHidden = false
            self.sortingButton.setImage(UIImage(named: "Sort_Ascending"), for: .normal)
        case .descending:
            self.sortingButton.isHidden = false
            self.sortingButton.setImage(UIImage(named: "Sort_Descending"), for: .normal)
        }
    }
    
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.sortingButton.isHidden = true
        self.mainLabel.textAlignment = .left
        self.sortOrder = .none
    }
}

