//
// Copyright (c) 2018 Marco Conti
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

private let contentChangeNotificationName = Notification.Name(rawValue: "SelectedObjectsContentChange")

/// List of selected objects
class SelectedObjects<Object: Equatable>: Sequence {
    
    func makeIterator() -> IndexingIterator<[Object]> {
        return self.selectedObjects.makeIterator()
    }
    
    /// List of selected objects
    private(set) var selectedObjects: [Object] = [] {
        didSet {
            if oldValue != self.selectedObjects {
                NotificationCenter.default.post(
                    name: contentChangeNotificationName,
                    object: self)
            }
        }
    }
    
    /// The selection status of an object
    subscript(object: Object) -> Bool {
        get {
            return self.isSelected(object)
        }
        set {
            if newValue {
                self.select(object)
            } else {
                self.deselect(object)
            }
        }
    }
    
    /// Checks whether the given object is selected
    func isSelected(_ object: Object) -> Bool {
        // linear scan! can it be made faster without hashable?
        return self.selectedObjects.index(of: object) != nil
    }
    
    /// Adds one object to the selection
    func select(_ object: Object) {
        guard !isSelected(object) else { return }
        self.selectedObjects.append(object)
    }
    
    /// Adds object to the selection
    func select<T: Sequence>(_ objects: T) where T.Element == Object {
        objects.forEach { self.select($0) }
    }
    
    /// Remove one object from the selection
    func deselect(_ object: Object) {
        guard let index = self.selectedObjects.index(of: object) else { return }
        self.selectedObjects.remove(at: index)
    }
    
    /// Deselect all objects
    func deselectAll() {
        self.selectedObjects = []
    }
    
    /// Set the selected objects to the given collection
    func setSelection<T: Sequence>(_ objects: T) where T.Element == Object {
        self.selectedObjects = Array(objects)
    }
    
    /// Add observer for selection change
    func addObserver(block: @escaping (SelectedObjects<Object>)->()) -> Any {
        return NotificationCenter.default.addObserver(
            forName: contentChangeNotificationName,
            object: self,
            queue: nil,
            using: { note in
                guard let object = note.object as? SelectedObjects<Object> else { return }
                block(object)
        })
    }
    
    /// Remove observer for selection change
    func removeObserver(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer)
    }
}
