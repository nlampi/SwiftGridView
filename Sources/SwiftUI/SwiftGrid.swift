// SwiftGrid.swift
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
import UIKit

// MARK: - SwiftGrid

/**
 `SwiftGrid` is the SwiftUI entry point for the data grid, wrapping a `SwiftGridView` in a `UIViewRepresentable`.

 The grid remains datasource/delegate driven: provide an object conforming to `SwiftGridViewDataSource`
 (and optionally `SwiftGridViewDelegate`), the same way you would in UIKit. `SwiftGrid` retains both for the
 lifetime of the view, since `SwiftGridView` holds them weakly.

 Use `configure` to register cell and reusable view types on the underlying grid before first display.
 Change `reloadToken` to any new value to request a full `reloadData()` on the next SwiftUI update.

 ```swift
 SwiftGrid(dataSource: model, delegate: model, reloadToken: model.version) { gridView in
     gridView.register(MyCell.self, forCellWithReuseIdentifier: MyCell.reuseIdentifier())
 }
 ```
 */
public struct SwiftGrid: UIViewRepresentable {

    private let dataSource: SwiftGridViewDataSource
    private let delegate: SwiftGridViewDelegate?
    private let reloadToken: AnyHashable?
    private let configure: ((SwiftGridView) -> Void)?

    /**
     Creates a SwiftUI data grid.

     - Parameter dataSource: Object providing grid content. Retained for the lifetime of the view.
     - Parameter delegate: Object providing sizing and receiving interaction callbacks. Retained for the lifetime of the view.
     - Parameter reloadToken: Optional change marker. When a SwiftUI update sees a different value than the previous one, the grid calls `reloadData()`.
     - Parameter configure: Called once after the underlying `SwiftGridView` is created. Register cells and reusable views here.
     */
    public init(
        dataSource: SwiftGridViewDataSource,
        delegate: SwiftGridViewDelegate? = nil,
        reloadToken: AnyHashable? = nil,
        configure: ((SwiftGridView) -> Void)? = nil
    ) {
        self.dataSource = dataSource
        self.delegate = delegate
        self.reloadToken = reloadToken
        self.configure = configure
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(dataSource: dataSource, delegate: delegate, reloadToken: reloadToken)
    }

    public func makeUIView(context: Context) -> SwiftGridView {
        let gridView = SwiftGridView()
        gridView.dataSource = context.coordinator.dataSource
        gridView.delegate = context.coordinator.delegate

        configure?(gridView)

        return gridView
    }

    public func updateUIView(_ gridView: SwiftGridView, context: Context) {
        if context.coordinator.reloadToken != reloadToken {
            context.coordinator.reloadToken = reloadToken
            gridView.reloadData()
        }
    }

    /// Retains the datasource and delegate on behalf of the grid, which references them weakly.
    @MainActor
    public final class Coordinator {
        let dataSource: SwiftGridViewDataSource
        let delegate: SwiftGridViewDelegate?
        var reloadToken: AnyHashable?

        init(dataSource: SwiftGridViewDataSource, delegate: SwiftGridViewDelegate?, reloadToken: AnyHashable?) {
            self.dataSource = dataSource
            self.delegate = delegate
            self.reloadToken = reloadToken
        }
    }
}
