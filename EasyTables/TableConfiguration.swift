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

import Cocoa
import ClosureControls

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
    
    let name: String
    let stringToDisplay: (Object)->(String)
    let width: ColumnWidth
    
    public init(_ name: String, width: ColumnWidth = .M, _ stringToDisplay: @escaping (Object)->(String)) {
        self.name = name
        self.stringToDisplay = stringToDisplay
        self.width = width
    }
}

/// Identifier for a text view cell
let TextCellViewIdentifier = "EasyDialogs_TextCellViewIdentifier"

/// Table data source backed by an array
/// At initialization, it is associated with a specific instance of NSTableView
/// and will create the necessary columns on that NSTableView
public class TableConfiguration<Object: Equatable> {
    
    /// Internal data source associated with the table
    public let dataSource: GenericTableDataSource<Object>
    
    /// Creates a table configuration and applies it to a table
    /// The configuration needs to be retained as long as the table
    /// is retained
    /// - parameter initialObjects: objects to display in the table
    /// - parameter columns: columns to display in the table. Any existing
    ///     column in the table is discarded
    /// - parameter contextMenuOperations: entries of the contextual menu to display
    ///     when right-clicking on a table row
    /// - parameter table: the table to apply this configuration to
    /// - allowMultipleSelection: whether multiple rows can be selected in the table
    
    public init<Objects: Collection>(initialObjects: Objects,
                columns: [ColumnDefinition<Object>],
                contextMenuOperations: [ObjectOperation<Object>],
                table: NSTableView,
                allowMultipleSelection: Bool,
                selectionCallback: @escaping ([Object])->(Void))
        where Objects.Iterator.Element == Object
    {
        self.dataSource = GenericTableDataSource(
            initialObjects: Array(initialObjects),
            columns: columns,
            contextMenuOperations: contextMenuOperations,
            table: table,
            allowMultipleSelection: allowMultipleSelection,
            selectionCallback: selectionCallback
        )
        
        table.dataSource = self.dataSource
        table.delegate = self.dataSource
        
        var columnsLookup: [String: ColumnDefinition<Object>] = [:]
        columns.forEach {
            columnsLookup[$0.name.lowercased()] = $0
        }
        
        TableConfiguration.setupTable(table, columns: columns, multiSelection: allowMultipleSelection)
        self.setupMenu(for: table, operations: contextMenuOperations)
    }
    
    /// Content of the table
    public var content: [Object] {
        return self.dataSource.sortedObjects
    }
    
    /// Sets the content of the table
    public func setContent<Objects: Collection>(_ content: Objects) where Objects.Iterator.Element == Object {
        self.dataSource.update(newObjects: Array(content))
    }
}

extension TableConfiguration {

    /// Sets up table columns and selection methods
    fileprivate static func setupTable(
        _ table: NSTableView,
        columns: [ColumnDefinition<Object>],
        multiSelection: Bool)
    {
        let preColumns = table.tableColumns
        preColumns.forEach {
            table.removeTableColumn($0)
        }
                
        columns.forEach { cdef in
            let column = NSTableColumn()
            column.title = cdef.name
            column.identifier = cdef.name.lowercased()
            column.isEditable = false
            column.minWidth = cdef.width.width
            column.maxWidth = cdef.width.width * 2
            column.sortDescriptorPrototype = NSSortDescriptor(key: column.title, ascending: false) {
                let value1 = cdef.stringToDisplay($0.0 as! Object)
                let value2 = cdef.stringToDisplay($0.1 as! Object)
                return value1.compare(value2)
            }
            table.addTableColumn(column)
        }
        
        table.allowsEmptySelection = true
        table.allowsColumnSelection = false
        table.allowsTypeSelect = true
        table.allowsMultipleSelection = multiSelection
    }
    
    /// Sets up the contextual menu for the table
    fileprivate func setupMenu(
        for table: NSTableView,
        operations: [ObjectOperation<Object>]
        ) {
        guard !operations.isEmpty else {
            table.menu = nil
            return
        }
        let menu = NSMenu()
        operations.forEach { operation in
            let item = ClosureMenuItem(title: operation.label) { [weak self] _ in
                guard let `self` = self else { return }
                let selectedObjects = self.targetObjectsForContextualOperation
                guard !selectedObjects.isEmpty else { return }
                operation.action(selectedObjects)
            }
            menu.addItem(item)
            item.isEnabled = true
        }
        table.menu = menu
    }
    
    /// Objects that should be affected by a contextual operation
    fileprivate var targetObjectsForContextualOperation: [Object] {
        let selectedIndex = self.dataSource.table.selectedRowIndexes
        let clickedIndex = self.dataSource.table.clickedRow
        
        let indexesToUse: [Int]
        if clickedIndex != -1 && !selectedIndex.contains(clickedIndex) {
             indexesToUse = [clickedIndex]
        } else {
            indexesToUse = selectedIndex.map { $0 }
        }
        return indexesToUse.flatMap(self.dataSource.value(row:))
    }
}

/// Contextual operations to perform on an object
public struct ObjectOperation<Object> {
    
    public let label: String
    public let action: ([Object])->()
    public let needsConfirmation: Bool
    
    public init(label: String, needsConfirmation: Bool = false, action: @escaping ([Object])->()) {
        self.label = label
        self.action = action
        self.needsConfirmation = needsConfirmation
    }
}

extension ComparisonResult {
    
    /// Invert the result of a comparison
    var inverted: ComparisonResult {
        switch self {
        case .orderedAscending:
            return .orderedDescending
        case .orderedDescending:
            return .orderedAscending
        case .orderedSame:
            return .orderedSame
        }
    }
}
