//
//  BasicNibCell.swift
//  SwiftGridExample
//
//  Created by nlampi on 6/17/17.
//  Copyright © 2017 nlampi. All rights reserved.
//

import Foundation
import UIKit
import SwiftGridView

class BasicNibCell : SwiftGridCell {
    
    @IBOutlet weak var textLabel: UILabel!
    
    
    open override class func reuseIdentifier() -> String {
        
        return "BasicNibCellReuseId"
    }
}
