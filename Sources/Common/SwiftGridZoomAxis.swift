// SwiftGridZoomAxis.swift
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

/// The axis or axes affected when a `SwiftGridView` is zoomed, either by pinch
/// or by setting `zoomScale` directly.
public enum SwiftGridZoomAxis: Sendable {

    /// Only column widths scale; row heights are left alone. This is the
    /// default, and matches the pinch behavior prior to 1.1.0.
    case horizontal

    /// Only row heights scale; column widths are left alone.
    case vertical

    /// Column widths and row heights scale together, the way a spreadsheet app
    /// zooms its grid. Cell *content* is not scaled: implement
    /// `dataGridView(_:didChangeZoomScale:)` to resize fonts alongside the grid.
    case both

    /// Whether column widths scale with the zoom.
    public var scalesHorizontally: Bool {

        return self == .horizontal || self == .both
    }

    /// Whether row heights scale with the zoom.
    public var scalesVertically: Bool {

        return self == .vertical || self == .both
    }
}
