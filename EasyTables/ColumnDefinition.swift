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
    case custom(size: CGFloat)
    
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
    let name: String
    /// Derive the string to display from the object
    let stringToDisplay: (Object)->(String)
    /// Comparison operator
    let comparison: Comparison<Object>
    /// Witdh of the column
    let width: ColumnWidth
    
    public init(_ name: String,
                width: ColumnWidth = .M,
                comparison: Comparison<Object>? = nil,
                _ stringToDisplay: @escaping (Object)->(String)
                ) {
        self.name = name
        self.stringToDisplay = stringToDisplay
        self.width = width
        self.comparison = comparison ?? ValueComparison({ obj in
            return stringToDisplay(obj)
        })
    }
}

/// Compare two objects
public class Comparison<Object> {
    
    /// Sort two values
    public func compare(lhs: Any, rhs: Any) -> ComparisonResult {
        return String(describing: lhs).compare(String(describing: rhs))
    }
}

/// A comparison performed by converting the object into a comparable value
public class ValueComparison<Object, SortingValue: Comparable>: Comparison<Object> {
    
    /// Derive the sorting value from the object
    let sortableValue: (Object)->(SortingValue)
    
    public init(_ sortableValue: @escaping (Object)->(SortingValue)) {
        self.sortableValue = sortableValue
    }
    
    override public func compare(lhs: Any, rhs: Any) -> ComparisonResult {
        guard let left = lhs as? Object,
            let right = rhs as? Object
            else { return ComparisonResult.orderedSame }
        let leftValue = self.sortableValue(left)
        let rightValue = self.sortableValue(right)
        
        switch (leftValue, rightValue) {
        case let (l, r) where l == r:
            return ComparisonResult.orderedSame
        case let (l, r) where l > r:
            return ComparisonResult.orderedDescending
        case let (l, r) where l < r:
            return ComparisonResult.orderedAscending
        default:
            return ComparisonResult.orderedSame
        }
    }
}
