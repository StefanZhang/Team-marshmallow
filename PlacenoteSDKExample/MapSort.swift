//
//  MapSort.swift
//  PlacenoteSDKExample
//
//  Created by Team Herman Miller on 3/15/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import Foundation

//func quickmapsort<T: Comparable>(_ a: [T]) -> [T] {
//    guard a.count > 1 else { return a }
//
//    let pivot = a[a.count/2]
//    let less = a.filter { $0 < pivot }
//    let equal = a.filter { $0 == pivot }
//    let greater = a.filter { $0 > pivot }
//
//    return quickmapsort(less) + equal + quickmapsort(greater)
//}
protocol Queue {
    associatedtype DataType: Comparable
    
    /**
     Inserts a new item into the queue.
     - parameter item: The item to add.
     - returns: Whether or not the insert was successful.
     */
    @discardableResult func add(_ item: DataType) -> Bool
    
    /**
     Removes the first item in line.
     - returns: The removed item.
     - throws: An error of type QueueError.
     */
    @discardableResult func remove() throws -> DataType
    
    /**
     Gets the first item in line and removes it from the queue.
     - returns: An Optional containing the first item in the queue.
     */
    func dequeue() -> DataType?
    
    /**
     Gets the first item in line, without removing it from the queue.
     - returns: An Optional containing the first item in the queue.
     */
    func peek() -> DataType?
    
    /**
     Clears the queue.
     */
    func clear() -> Void
}

class PriorityQueue {
    var queue = Array<Vertex<String>>()
    @discardableResult
    public func add(_ item: Vertex<String>) -> Bool {
        self.queue.append(item)
        self.heapifyUp(from: self.queue.count - 1)
        return true
    }
    
    @discardableResult
    public func remove() throws -> Vertex<String> {
        guard self.queue.count > 0 else {
            let NodeError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Object does not exist"])
            throw NodeError
        }
        return self.popAndHeapifyDown()
    }
    
    public func dequeue() -> Vertex<String>? {
        guard self.queue.count > 0 else {
            return nil
        }
        return self.popAndHeapifyDown()
    }
    
    public func peek() -> Vertex<String>? {
        return self.queue.first
    }
    
    public func clear() {
        self.queue.removeAll()
    }
    
    /**
     Pops the first item in the queue and restores the min heap order of the queue by moving the root item towards the end of the queue.
     - returns: The first item in the queue.
     */
    private func popAndHeapifyDown() -> Vertex<String> {
        let firstItem = self.queue[0]
        
        if self.queue.count == 1 {
            self.queue.remove(at: 0)
            return firstItem
        }
        
        self.queue[0] = self.queue.remove(at: self.queue.count - 1)
        
        self.heapifyDown()
        
        return firstItem
    }
    
    private func find_parent(index: Int) -> Int {
        var parent = 0.0
        if index % 2 == 0
        {
            parent = (Double(index) / 2) - 1
        }
        else
        {
            parent = Double(index) / 2
            parent.round(.down)
        }
        return Int(parent)
    }
    
    private func find_child(index: Int, side: String) -> Int
    {
        if side == "Right"
        {
            return (index * 2) + 2
        }
        return (index * 2) + 1
    }
    
    /**
     Restores the min heap order of the queue by moving an item towards the beginning of the queue.
     - parameter index: The index of the item to move.
     */
    private func heapifyUp(from index: Int) {
        var child = index
        var parent = self.find_parent(index: child)
        let mid = index
        while parent >= 0 && parent > child {
            child = parent
            parent = find_parent(index: mid)
        }
    }
    
    /**
     Restores the min heap order of the queue by moving the root item towards the end of the queue.
     */
    private func heapifyDown() {
        var parent = 0
        
        while true {
            let leftChild = find_child(index: parent, side: "Left")
            if leftChild >= self.queue.count {
                break
            }
            
            let rightChild = find_child(index: parent, side: "Right")
            var minChild = leftChild
            if rightChild < self.queue.count && minChild > rightChild {
                minChild = rightChild
            }

            if parent > minChild {
                parent = minChild
            } else {
                break
            }
        }
}
}
