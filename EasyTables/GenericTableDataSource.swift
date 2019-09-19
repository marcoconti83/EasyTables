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

public class GenericTableDataSource<Object: Equatable>: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    /// Objects in the table, sorted
    private(set) var sortedObjects: [Object] = []
    
    /// Initial objects
    private(set) var originalObjects: [Object] = []
    
    /// Table associated with this data source
    let table: NSTableView
    
    /// Columns in the table
    let columns: [String: ColumnDefinition<Object>]
    
    /// Called when the selection changes
    let selectionCallback: ([Object])->(Void)
    
    /// Currently applied filter
    public var filter: ((Object)->Bool)? {
        didSet {
            self.recalculateSource()
        }
    }
    
    /// List of objects currently selected with checkbox
    var checkboxSelected = SelectedObjects<Object>()
    
    /// Checkbox selection change listener
    private var checkboxSelectionListenerToken: Any? = nil
    
    /// Selection model for the table
    let selectionModel: SelectionModel
    
    init(initialObjects: [Object],
         columns: [ColumnDefinition<Object>],
         contextMenuOperations: [ObjectOperation<Object>] = [],
         table: NSTableView,
         selectionModel: SelectionModel,
         selectionCallback: @escaping ([Object])->(Void) = { _ in }
        ) {
        self.filter = nil
        self.table = table
        self.selectionModel = selectionModel
        self.columns = Dictionary(
            columns.map { ($0.identifier, $0) },
            uniquingKeysWith: { a, b in a })
        self.selectionCallback = selectionCallback
        super.init()
        self.checkboxSelectionListenerToken = self.checkboxSelected.addObserver {
            [weak self] _ in
            guard let `self` = self else { return }
            self.selectionCallback(self.selectedItems)
        }
        self.update(newObjects: initialObjects, invokeSelectionCallback: false)
    }
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return self.sortedObjects.count
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        guard
            let entry = self.value(row: row),
            let tableColumn = tableColumn,
            let column = columns[tableColumn.identifier.rawValue]
            else {
                return nil
        }
        
        let cellIdentifier = tableColumn.identifier
        let value = column.value(entry)
        return self.viewForValue(value, in: tableView, cellIdentifier: cellIdentifier)
    }
    
    /// Returns the best view to represent an item
    private func viewForValue(_ value: Any,
                              in tableView: NSTableView,
                              cellIdentifier: NSUserInterfaceItemIdentifier
                              ) -> NSView
    {
        // TODO: use reusable views that are registered on the table with an identifier.
        // I could not get them to register when in a framework though, it fails to find the xib
        if let viewValue = value as? NSView {
            return viewValue
        }
        if let imageValue = value as? NSImage {
            let imageView = NSImageView()
            imageView.image = imageValue
            return imageView
        }
        let field = (tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTextField) ?? {
            let field = NSTextField()
            field.identifier = cellIdentifier
            field.isBezeled = false
            field.isBordered = false
            field.drawsBackground = false
            field.usesSingleLineMode = true
            field.cell?.lineBreakMode = .byClipping
            return field
            }()
        if let attributed = value as? NSAttributedString {
            field.attributedStringValue = attributed
        } else if let bool = value as? Bool {
            field.stringValue = bool ? "✅" : "❌"
        } else {
            field.stringValue = "\(value)"
        }
        field.isEditable = false
        return field
    }
    
    public func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        self.resortItems()
        self.table.reloadData()
    }
    
    public func tableViewSelectionDidChange(_ notification: Notification) {
        self.selectionCallback(self.selectedItems)
    }
    
    public func selectionShouldChange(in tableView: NSTableView) -> Bool {
        return !self.selectionModel.blocksNativeSelection
    }
    
    /// Update the objects, re-apply filter and sorting
    func update(newObjects: [Object], invokeSelectionCallback: Bool = true) {
        self.originalObjects = newObjects
        self.recalculateSource()
        if invokeSelectionCallback {
            self.selectionCallback(self.selectedItems)
        }
    }
    
    /// Refilter original objects then sort them
    private func recalculateSource() {
        self.filterItems()
        self.resortItems()
        self.table.reloadData()
    }
    
    /// Filter the sorted objects
    private func filterItems() {
        if let filter = self.filter {
            self.sortedObjects = self.originalObjects.filter(filter)
        } else {
            self.sortedObjects = self.originalObjects
        }
    }
    
    /// Returns the object at the given row
    func value(row: Int) -> Object? {
        guard row >= 0, row < self.sortedObjects.count else { return nil }
        return self.sortedObjects[row]
    }
    /// Resort the items according to description
    private func resortItems() {
        let sortingFunctions = self.table.sortDescriptors.compactMap {
            descriptor -> ((Object, Object)->ComparisonResult)? in
            guard let title = descriptor.key,
                let column = self.columns[title.lowercased()]
                else { return nil }
            let ascending = descriptor.ascending
            return { v1, v2 -> ComparisonResult in
                let comparison = column.comparison(v1, v2)
                if ascending {
                    return comparison.inverted
                }
                return comparison
            }
        }
        guard !sortingFunctions.isEmpty else { return }
        self.sortedObjects.sort { (c1, c2) -> Bool in
            for f in sortingFunctions {
                switch f(c1, c2) {
                case .orderedSame:
                    continue
                case .orderedAscending:
                    return true
                case .orderedDescending:
                    return false
                }
            }
            return true
        }
    }
        
    /// Select the item, if present. This causes a linear scan of the table (`O(n)`).
    public func select(item: Object, extendSelection: Bool = false) {
        guard let index = self.sortedObjects.firstIndex(where: { $0 == item }) else { return }
        self.table.selectRowIndexes(IndexSet(integersIn: index...index), byExtendingSelection: extendSelection)
    }
    
    /// Select the items, if present. 
    /// This causes a linear scan of the table for each element in the sequence (`O(n*m)`).
    public func select<SEQUENCE: Sequence>(items: SEQUENCE, extendSelection: Bool = false)
        where SEQUENCE.Iterator.Element == Object
    {
        if self.selectionModel.requiresManualSelectionTracking {
            if !extendSelection {
                self.checkboxSelected.setSelection(items)
            } else {
                self.checkboxSelected.select(items)
            }
            self.table.reloadData()
        } else {
            let indexes = items.compactMap { item in self.sortedObjects.firstIndex(where: { $0 == item }) }
            self.table.selectRowIndexes(IndexSet(indexes), byExtendingSelection: extendSelection)
        }
    }
    
    /// The items currently selected in the table
    public var selectedItems: [Object] {
        if self.selectionModel.requiresManualSelectionTracking {
            return self.checkboxSelected.selectedObjects
        } else {
            return self.table.selectedRowIndexes.map {
                self.sortedObjects[$0]
            }
        }
    }
    
    /// Whether an object is selected
    /// - note: this will cause two linear scans of the elements
    func isSelected(_ object: Object) -> Bool {
        return self.selectedItems.contains(object)
    }
}
