//
//  BasicNibReusableView.swift
//  SwiftGridExample
//
//  Created by nlampi on 6/17/17.
//  Copyright © 2017 nlampi. All rights reserved.
//

import Foundation
import UIKit
import SwiftGridView

open class BasicNibReusableView : SwiftGridReusableView {
    
    @IBOutlet weak var textLabel: UILabel!
    
    
    override open class func reuseIdentifier() -> String {
        
        return "BasicNibReusableViewReuseId"
    }
}
