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

public enum SelectionModel {
    /// Allow selection of one row, using native table selection mechanism
    case singleNative
    /// Allow selection of multiple rows, using native table selection mechanism
    case multipleNative
    /// Allow selection of multiple rows, using checkbox input
    case multipleCheckbox
    /// Do not allow selection
    case none
}

// MARK: - Table configuration
extension SelectionModel {
    /// Sets the corresponding selection mode on a table view
    func configureTableSelectionProperties(_ table: NSTableView) {
        table.allowsEmptySelection = true
        table.allowsColumnSelection = false
        table.allowsTypeSelect = !self.blocksNativeSelection
        table.allowsMultipleSelection = self == .multipleNative
    }
    
    /// Whether this mode requires an extra checkbox column
    var requiresCheckboxColumn: Bool {
        return self == .multipleCheckbox
    }
    
    /// Whether this mode requires manual tracking of selection
    var requiresManualSelectionTracking: Bool {
        return self == .multipleCheckbox
    }
    
    /// Whether this mode should inhibit the native selection mechanism
    var blocksNativeSelection: Bool {
        switch self {
        case .none:
            return true
        case .multipleCheckbox:
            return true
        default:
            return false
        }
    }
}

