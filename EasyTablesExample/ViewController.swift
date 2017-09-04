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

/// An example of how to use `TableConfiguration`
class ViewController: NSViewController {

    var configuration: TableConfiguration<String>!
    
    var objects = Set(["Action", "Engineering", "Cod", "Doodle"])
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let (scroll, table) = NSTableView.inScrollView()
        self.view.addSubview(scroll)
        
        scroll.createConstraintsToFillParent(self.view)
        
        self.configuration = TableConfiguration(
            initialObjects: objects,
            columns: [
                ColumnDefinition("Word", { $0 }),
                ColumnDefinition("Length", { "\($0.characters.count)" }),
            ],
            contextMenuOperations: [
                // Remove object from the table
                ObjectOperation(label: "Remove", action: {
                    [weak self] (items: [String]) -> Void in
                    guard let `self` = self else { return }
                    items.forEach {
                        self.objects.remove($0)
                    }
                    self.configuration.setContent(self.objects) // changing the content automatically updates the table
                }),
                // Uppercase the string(s)
                ObjectOperation(label: "Convert to uppercase", action: {
                    [weak self] (items: [String]) -> Void in
                    guard let `self` = self else { return }
                    items.forEach {
                        self.objects.remove($0)
                        self.objects.insert($0.uppercased())
                    }
                    self.configuration.setContent(self.objects) // changing the content automatically updates the table
                })
            ],
            table: table,
            allowMultipleSelection: true,
            selectionCallback: {
                /// Just print out something when selected
                print("Selection changed:")
                $0.forEach { print("Selected", $0) }
            })
    }
    
    override func keyUp(with event: NSEvent) {
        self.configuration.dataSource.select(items: ["Cod", "Action"])
    }
}
