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
import EasyTables
import ClosureControls
import Cartography

/// An example of how to use `TableConfiguration`
class TableViewController: NSViewController {

    private var tableSource: EasyTableSource<String>!
    
    private static let fishes = ["Cod", "Shark"]
    private static let items = ["Hammer", "Doodle", "Speaker"]
    private var objects = Set(fishes + items)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let selectButton = ClosureButton(label: "Select all Fish") { _ in
            self.tableSource.dataSource.select(items: TableViewController.fishes)
        }
        
        let filterButton = ClosureButton(label: "Filter out non-fish") { btn in
            guard let button = btn as? NSButton else { return }
            switch button.state {
            case .on:
                self.tableSource.dataSource.filter = { TableViewController.fishes.contains($0) }
            case .off:
                self.tableSource.dataSource.filter = nil
            default:
                return
            }
        }
        filterButton.setButtonType(.switch)
        
        let (scroll, table) = NSTableView.inScrollView()
        self.createLayoutConstraints(table: scroll, button1: selectButton, button2: filterButton)
        
        self.createTableSource(for: table)

    }
    
    private func createTableSource(for table: NSTableView) {
        let imageDirectory = RandomImageDirectory()
        self.tableSource = EasyTableSource(
            initialObjects: self.objects,
            columns: [
                ColumnDefinition(name: "Word", value: { $0.boldAttributed }),
                ColumnDefinition(name: "Length", width: .S, value: { $0.characters.count }),
                ColumnDefinition(name: "Image", width: .S, value: { imageDirectory.image(for: $0) as Any } ),
                ColumnDefinition(name: "Starts with C", width: .S, value: { $0.starts(with: "C") }),
                ColumnDefinition(name: "Control", width: .S, value: { let b = NSButton(); b.title = $0; return b })
            ],
            contextMenuOperations: [
                // Remove object from the table
                ObjectOperation(label: "Remove", action: {
                    [weak self] (items: [String]) -> Void in
                    guard let `self` = self else { return }
                    items.forEach {
                        self.objects.remove($0)
                    }
                    self.tableSource.setContent(self.objects) // changing the content automatically updates the table
                }),
                // Uppercase the string(s)
                ObjectOperation(label: "Convert to uppercase", action: {
                    [weak self] (items: [String]) -> Void in
                    guard let `self` = self else { return }
                    items.forEach {
                        self.objects.remove($0)
                        self.objects.insert($0.uppercased())
                    }
                    self.tableSource.setContent(self.objects) // changing the content automatically updates the table
                })
            ],
            table: table,
            selectionModel: .multipleCheckbox,
            selectionCallback: {
                /// Just print out something when selected
                print("Selection changed:")
                $0.forEach { print("\t", $0) }
            })
    }
    
    private func createLayoutConstraints(table: NSView, button1: NSView, button2: NSView) {
        self.view.addSubview(table)
        self.view.addSubview(button1)
        self.view.addSubview(button2)
        
        let space: CGFloat = 10
        constrain(table, button1, button2, self.view) { table, b1, b2, frame in
            table.bottom == frame.bottom - space
            table.left == frame.left + space
            table.right == frame.right - space
            
            b1.leading == frame.leading + space
            b1.trailing == b2.leading - space
            b2.trailing == frame.trailing - space
            b1.top == b2.top
            b1.top == frame.top + space
            b1.bottom == b2.bottom
            b1.width == b2.width
            
            table.top == b1.bottom + space
        }
    }
    
}

extension String {
    
    var boldAttributed: NSAttributedString {
        let font = NSFont.boldSystemFont(ofSize: 0)
        return NSAttributedString(string: self, attributes: [NSAttributedStringKey.font: font])
    }
}
