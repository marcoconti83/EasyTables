//
// Copyright (c) 2017 Marco Conti
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
//

import Foundation

extension NSTableView {
    
    /// Returns a table view inside a scroll view
    public static func inScrollView() -> (NSScrollView, NSTableView) {
        let container = NSScrollView()
        let table = NSTableView()
        container.documentView = table
        container.hasVerticalScroller = true
        container.hasHorizontalScroller = true
        return (container, table)
    }
}

extension NSView {
    
    /// Creates the autolayout constraints needed for this view to fill the parent view,
    /// and sets them on the parent as active
    @discardableResult public func createConstraintsToFillParent(_ parent: NSView) -> [NSLayoutConstraint] {
        self.translatesAutoresizingMaskIntoConstraints = false
        let attributes: [NSLayoutAttribute] = [.top, .bottom, .trailing, .leading]
        let constraints = attributes.map {
            NSLayoutConstraint(item: parent, attribute: $0, relatedBy: .equal, toItem: self, attribute: $0, multiplier: 1, constant: 0) }
        constraints.forEach { $0.isActive = true }
        parent.addConstraints(constraints)
        return constraints
    }
}
