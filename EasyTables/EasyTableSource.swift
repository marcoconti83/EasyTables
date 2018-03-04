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

/// Identifier for a text view cell
let TextCellViewIdentifier = "EasyDialogs_TextCellViewIdentifier"

/// Table data source backed by an array
/// At initialization, it is associated with a specific instance of NSTableView
/// and will create the necessary columns on that NSTableView
public class EasyTableSource<Object: Equatable> {
        
    /// Internal data source associated with the table
    private(set) public var dataSource: GenericTableDataSource<Object>! = nil
    
    public var table: NSTableView {
        return self.dataSource.table
    }
    
    public typealias ConfirmationCallback = (Bool)->()
    
    /// Creates a table configuration and applies it to a table
    /// The configuration needs to be retained as long as the table
    /// is retained
    /// - parameter initialObjects: objects to display in the table
    /// - parameter columns: columns to display in the table. Any existing
    ///     column in the table is discarded
    /// - parameter contextMenuOperations: entries of the contextual menu to display
    ///     when right-clicking on a table row
    /// - parameter table: the table to apply this configuration to. If not specified, 
    ///     will create a new one
    /// - parameter selectionModel: whether multiple rows can be selected in the table
    /// - parameter selectionCallback: callback invoked when the selection changes
    
    public init<Objects: Collection>(initialObjects: Objects,
                columns: [ColumnDefinition<Object>],
                contextMenuOperations: [ObjectOperation<Object>],
                table: NSTableView? = nil,
                selectionModel: SelectionModel = .singleNative,
                operationConfirmationCallback: @escaping (ConfirmationCallback, String)->() = ConfirmationAlert.ask,
                selectionCallback: (([Object])->(Void))? = nil)
        where Objects.Iterator.Element == Object
    {
        let columns = (selectionModel.requiresCheckboxColumn ? [self.checkboxColumn] : []) + columns
        let table = table ?? NSTableView()
        self.dataSource = GenericTableDataSource(
            initialObjects: Array(initialObjects),
            columns: columns,
            contextMenuOperations: contextMenuOperations,
            table: table,
            selectionModel: selectionModel,
            selectionCallback: selectionCallback ?? { _ in }
        )
        
        table.dataSource = self.dataSource
        table.delegate = self.dataSource
        self.setupTable(columns: columns,
                        selectionModel: selectionModel)
        self.setupMenu(operations: contextMenuOperations,
                       operationConfirmationCallback: operationConfirmationCallback)
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

extension EasyTableSource {

    /// Sets up table columns and selection methods
    fileprivate func setupTable(
        columns: [ColumnDefinition<Object>],
        selectionModel: SelectionModel)
    {
        let preColumns = self.table.tableColumns
        preColumns.forEach {
            self.table.removeTableColumn($0)
        }
        
        columns.forEach { cdef in
            let column = NSTableColumn()
            column.title = cdef.name
            column.identifier = NSUserInterfaceItemIdentifier(rawValue: cdef.identifier)
            column.isEditable = false
            column.minWidth = cdef.width.width
            column.maxWidth = cdef.width.width * 2
            column.sortDescriptorPrototype = NSSortDescriptor(key: cdef.identifier, ascending: false) {
                let value1 = cdef.value($0 as! Object)
                let value2 = cdef.value($1 as! Object)
                return "\(value1)".compare("\(value2)")
            }
            self.table.addTableColumn(column)
        }
        selectionModel.configureTableSelectionProperties(self.table)
        self.setInitialSorting(selectionModel: selectionModel)
    }
    
    /// Set the initial sort descriptor for the table
    fileprivate func setInitialSorting(selectionModel: SelectionModel) {
        let initialSortingIndex = selectionModel.requiresCheckboxColumn ? 1 : 0
        if initialSortingIndex < self.table.tableColumns.count {
            let sortingColumn = self.table.tableColumns[initialSortingIndex]
            self.table.sortDescriptors = [sortingColumn.sortDescriptorPrototype].flatMap { $0 }
        }
    }
    
    /// Sets up the contextual menu for the table
    fileprivate func setupMenu(
        operations: [ObjectOperation<Object>],
        operationConfirmationCallback: @escaping (ConfirmationCallback, String)->()
        ) {
        guard !operations.isEmpty else {
            self.table.menu = nil
            return
        }
        let menu = NSMenu()
        operations.forEach { operation in
            let item = ClosureMenuItem(title: operation.label) { [weak self] _ in
                guard let `self` = self else { return }
                let selectedObjects = self.targetObjectsForContextualOperation
                guard !selectedObjects.isEmpty else { return }
                if operation.needsConfirmation {
                    operationConfirmationCallback({
                        if $0 {
                            operation.action(selectedObjects)
                        }
                    }, operation.label)
                } else {
                    operation.action(selectedObjects)
                }
            }
            menu.addItem(item)
            item.isEnabled = true
        }
        self.table.menu = menu
    }
    
    private var checkboxColumn: ColumnDefinition<Object> {
        return ColumnDefinition(name: "✅",
                                width: .custom(10),
                                alignment: .center)
        { obj in
            let checkbox = ClosureButton()
            checkbox.closure =  { [weak self, weak checkbox] _ in
                guard let `self` = self, let checkbox = checkbox else { return }
                let isSelected = checkbox.state == NSControl.StateValue.on
                self.dataSource.checkboxSelected[obj] = isSelected
            }
            checkbox.setButtonType(.switch)
            checkbox.title = ""
            checkbox.state = self.dataSource.isSelected(obj) ? NSControl.StateValue.on : NSControl.StateValue.off
            return checkbox
        }
    }
    
    /// Objects that should be affected by a contextual operation
    fileprivate var targetObjectsForContextualOperation: [Object] {
        let selectedObjects = self.dataSource.selectedItems
        let clickedObject = self.dataSource.value(row: self.dataSource.table.clickedRow)
        
        if let clicked = clickedObject, !selectedObjects.contains(clicked) {
            return [clicked]
        } else {
            return selectedObjects
        }
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


public struct ConfirmationAlert {
    static func OKCancel(message: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    public static func ask(callback: (Bool)->(), operation: String) {
        let response = OKCancel(message: "\(operation)\nAre you sure?")
        callback(response)
    }
}
