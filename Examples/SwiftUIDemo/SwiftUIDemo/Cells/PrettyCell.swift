//
// PrettyCell.swift
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


class PrettyCell : SwiftGridCell {
    var mainHost: UIHostingController<PrettyContentView>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureDefaults()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configureDefaults()
    }
    
    func configureDefaults() {
        let mainView = PrettyContentView(mainText: "", alignment: .leading)
        mainHost = UIHostingController(rootView: mainView)
        mainHost!.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainHost!.view)
        
        NSLayoutConstraint.activate([
            mainHost!.view.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            mainHost!.view.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            mainHost!.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainHost!.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    
    // MARK: - Public Methods
    
    func configureFor(_ text:String, and columnSettings:PrettyDataPoint) {
        mainHost?.rootView.mainText = text
        mainHost?.rootView.alignment = columnSettings.alignment
    }
    
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        mainHost?.rootView.alignment = .leading
    }
    
    static override func reuseIdentifier() -> String {
        
        "PrettyRowCellReuseID"
    }
}
