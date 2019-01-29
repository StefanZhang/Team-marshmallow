//
//  Vertex.swift
//  PlacenoteSDKExample
//
//  Created by John Riley on 1/29/19.
//  Copyright © 2019 Vertical. All rights reserved.
//
// Referance
// https://www.raywenderlich.com/773-swift-algorithm-club-graphs-with-adjacency-list
//

import Foundation

public struct Vertex<T: Hashable> {
    var data: T
}

extension Vertex: Hashable {
    public var hashValue: Int { // 1
        return "\(data)".hashValue
    }
    
    static public func ==(lhs: Vertex, rhs: Vertex) -> Bool { // 2
        return lhs.data == rhs.data
    }
}

extension Vertex: CustomStringConvertible {
    public var description: String {
        return "\(data)"
    }
}

