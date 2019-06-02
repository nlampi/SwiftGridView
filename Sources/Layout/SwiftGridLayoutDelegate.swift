// SwiftGridLayoutDelegate.swift
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
import UIKit


// MARK: - SwiftGridLayoutDelegate

/**
 The `SwiftGridLayoutDelegate` is used for retrieving extra required information to properly display and layout the data grid.
 */
@objc protocol SwiftGridLayoutDelegate : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightFor row:Int, at indexPath: IndexPath) -> CGFloat
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForSupplementaryViewOfKind kind: String, atIndexPath indexPath: IndexPath) -> CGFloat
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForSupplementaryViewOfKind kind: String, atIndexPath indexPath: IndexPath) -> CGSize
    
    func collectionView(_ collectionView: UICollectionView, numberOfColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int
    
    func collectionView(_ collectionView: UICollectionView, groupedColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> [[Int]]
    
    func collectionView(_ collectionView: UICollectionView, numberOfFrozenColumnsForLayout collectionViewLayout: UICollectionViewLayout) -> Int
    
    func collectionView(_ collectionView: UICollectionView, totalColumnWidthForLayout collectionViewLayout: UICollectionViewLayout) -> CGFloat
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfRowsInSection sectionIndex: Int) -> Int
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfFrozenRowsInSection sectionIndex: Int) -> Int
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, widthOfColumnAtIndex columnIndex: Int) -> CGFloat
}
