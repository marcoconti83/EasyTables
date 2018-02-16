# EasyTables

EasyTables allows for an easy way of programmatically creating and setting up a `NSTableView` to display textual information backed by a collection of elements. It also allows for easy creation of contextual menus (right-click "pop-up" menu) and to easily react on selection, without using interface builder. The columns are also sortable by string comparison on the displayed string.

## How to use
It's as simple as defining the list of colums, what operations should appear in the contextual menu, and how to react to selection.

Here's an example, that uses no interface builder and no XIB to programmatically create a `NSTableView`, populate its values and define some operations:
```swift
import Cocoa
import EasyTables

class ViewController: NSViewController {

    var configuration: EasyTableSource<String>!
    
    var objects = Set(["Action", "Engineering", "Cod", "Doodle"])
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let (scroll, table) = NSTableView.inScrollView()
        self.view.addSubview(scroll)
        scroll.createConstraintsToFillParent(self.view)
        
        self.configuration = EasyTableSource(
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
}
```

The result of this setup is shown in the following screenshot:
![Screenshot of table](https://github.com/marcoconti83/EasyTables/blob/master/docs/table-example.png?raw=true)

## Credits
The images used in the example are from [Unsplash](https://unsplash.com).

