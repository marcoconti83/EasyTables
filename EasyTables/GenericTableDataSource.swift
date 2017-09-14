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
    
    init(initialObjects: [Object],
         columns: [ColumnDefinition<Object>],
         contextMenuOperations: [ObjectOperation<Object>] = [],
         table: NSTableView,
         allowMultipleSelection: Bool,
         selectionCallback: @escaping ([Object])->(Void) = { _ in }
        ) {
        self.filter = nil
        self.table = table
        var columnsLookup: [String: ColumnDefinition<Object>] = [:]
        columns.forEach {
            columnsLookup[$0.name.lowercased()] = $0
        }
        self.columns = columnsLookup
        self.selectionCallback = selectionCallback
        super.init()
        self.update(newObjects: initialObjects)
    }
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return self.sortedObjects.count
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        guard
            let entry = self.value(row: row),
            let tableColumn = tableColumn,
            let column = columns[tableColumn.identifier]
            else {
                return nil
        }
        
        let cellIdentifier = tableColumn.identifier
        // TODO: use reusable views that are registered on the table with an identifier.
        // I could not get them to register when in a framework though, it fails to find the xib
        let field = (tableView.make(withIdentifier: cellIdentifier, owner: self) as? NSTextField) ?? {
            let field = NSTextField()
            field.identifier = cellIdentifier
            field.isBezeled = false
            field.isBordered = false
            field.drawsBackground = false
            return field
            }()
        field.stringValue = "\(column.value(entry))"
        field.isEditable = false        
        return field
    }
    
    public func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        self.resortItems()
        self.table.reloadData()
    }
    
    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard let table = notification.object as? NSTableView else { return }
        let indexes = table.selectedRowIndexes
        let objects = indexes.map { self.sortedObjects[$0] }
        self.selectionCallback(objects)
    }
    
    /// Update the objects, re-apply filter and sorting
    func update(newObjects: [Object]) {
        self.originalObjects = newObjects
        self.recalculateSource()
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
        let sortingFunctions = self.table.sortDescriptors.flatMap {
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
        guard let index = self.sortedObjects.index(where: { $0 == item }) else { return }
        self.table.selectRowIndexes(IndexSet(integersIn: index...index), byExtendingSelection: extendSelection)
    }
    
    /// Select the items, if present. 
    /// This causes a linear scan of the table for each element in the sequence (`O(n*m)`).
    public func select<SEQUENCE: Sequence>(items: SEQUENCE, extendSelection: Bool = false)
        where SEQUENCE.Iterator.Element == Object
    {
        let indexes = items.flatMap { item in self.sortedObjects.index(where: { $0 == item }) }
        self.table.selectRowIndexes(IndexSet(indexes), byExtendingSelection: extendSelection)
    }
    
    /// The items currently selected in the table
    public var selectedItems: [Object] {
        return self.table.selectedRowIndexes.map {
            self.sortedObjects[$0]
        }
    }
}
