// PECountry.swift
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

class PECountry {
    var name:String = ""
    var capital:String = ""
    var continent:String = ""
    var currency:String = ""
    var phone:String = ""
    var tld:String = ""
    var population:Int = -1
    var area:Float = -1
    
    init(dictionary:[String:Any]) {
        self.name = dictionary["name"] as! String
        self.capital = dictionary["capital"] as! String
        self.continent = dictionary["continent"] as! String
        self.currency = dictionary["currency"] as! String
        self.phone = dictionary["phone"] as! String
        self.tld = dictionary["tld"] as! String
        
        let argPopulation = dictionary["population"] as! String
        if argPopulation != "" {
            self.population = Int(argPopulation)!
        }
        
        let argArea = dictionary["area"] as! String
        if argArea != "" {
            self.area = Float(argArea)!
        }
    }
}
