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

/// Width of the column
public enum ColumnWidth {
    case S
    case M
    case L
    case XL
    case custom(CGFloat)
    
    var width: CGFloat {
        switch self {
        case .S:
            return 25
        case .M:
            return 150
        case .L:
            return 300
        case .XL:
            return 500
        case .custom(let size):
            return size
        }
    }
}

/// Definition of how to display a column in a NSTableView
public struct ColumnDefinition<Object> {
    
    /// Name of the column
    public let name: String
    /// Derive the value to display from the object
    public let value: (Object)->(Any)
    /// Comparison operator
    public let comparison: (Object, Object)->ComparisonResult
    /// Witdh of the column
    public let width: ColumnWidth
    /// Alignment
    public let alignment: NSTextAlignment
    /// Internal ID
    private let generatedID: UUID = UUID()
    /// Column identifier
    let identifier: String
    
    public init(name: String,
                width: ColumnWidth = .M,
                alignment: NSTextAlignment = .left,
                comparison: ((Object, Object)->ComparisonResult)? = nil,
                value: @escaping (Object)->(Any)
                ) {
        self.identifier = (name + "_" + self.generatedID.uuidString).lowercased()
        self.name = name
        self.value = value
        self.width = width
        self.alignment = alignment
        self.comparison = comparison ?? { lhs, rhs in
            return bestEffortComparison(lhs: value(lhs), rhs: value(rhs))
        }
    }
}


/// A best effort at sorting two values of which we don't know the type
private func bestEffortComparison(lhs: Any, rhs: Any) -> ComparisonResult {
    switch (lhs, rhs) {
    case (let n1 as NSNumber, let n2 as NSNumber):
        return n1.compare(n2)
    case (let s1 as String, let s2 as String):
        return s1.compare(s2)
    default:
        return "\(lhs)".compare("\(rhs)")
    }
}

