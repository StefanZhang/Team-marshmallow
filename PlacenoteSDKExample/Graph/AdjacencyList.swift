//
//  AdjacencyList.swift
//  PlacenoteSDKExample
//
//  Created by John Riley on 1/29/19.
//  Copyright © 2019 Vertical. All rights reserved.
//
// Referance
// https://www.raywenderlich.com/773-swift-algorithm-club-graphs-with-adjacency-list
//

import Foundation

open class AdjacencyList<T: Hashable> {
    
    public var adjacencyDict : [Vertex<T>: [Edge<T>]] = [:]
    public init() {}
    
    fileprivate func addDirectedEdge(from source: Vertex<Element>, to destination: Vertex<Element>, weight: Double?) {
        let edge = Edge(source: source, destination: destination, weight: weight)
        adjacencyDict[source]?.append(edge)
    }
    
    fileprivate func addUndirectedEdge(vertices: (Vertex<Element>, Vertex<Element>), weight: Double?) {
        let (source, destination) = vertices
        addDirectedEdge(from: source, to: destination, weight: weight)
        addDirectedEdge(from: destination, to: source, weight: weight)
    }
}

extension AdjacencyList: Graphable {
    
    public typealias Element = T
    
    public func createVertex(data: Element) -> Vertex<Element> {
        let vertex = Vertex(data: data)
        
        if adjacencyDict[vertex] == nil {
            adjacencyDict[vertex] = []
        }
        
        return vertex
    }
    
    public func add(_ type: EdgeType, from source: Vertex<Element>, to destination: Vertex<Element>, weight: Double?) {
        switch type {
        case .directed:
            addDirectedEdge(from: source, to: destination, weight: weight)
        case .undirected:
            addUndirectedEdge(vertices: (source, destination), weight: weight)
        }
    }
    
    public func weight(from source: Vertex<Element>, to destination: Vertex<Element>) -> Double? {
        guard let edges = adjacencyDict[source] else {
            return nil
        }
        
        for edge in edges {
            if edge.destination == destination {
                return edge.weight
            }
        }
        
        return nil
    }
    
    
    public func edges(from source: Vertex<Element>) -> [Edge<Element>]? {
        return adjacencyDict[source]
    }
    
    public var description: CustomStringConvertible {
        var result = ""
        for (vertex, edges) in adjacencyDict {
            var edgeString = ""
            for (index, edge) in edges.enumerated() {
                if index != edges.count - 1 {
                    edgeString.append("\(edge.destination), ")
                } else {
                    edgeString.append("\(edge.destination)")
                }
            }
            result.append("\(vertex) ---> [ \(edgeString) ] \n ")
        }
        return result
    }
    
    public func aStar(start: Vertex<Element>, destination: Vertex<Element>) -> Array<Vertex<Element>>{
        var out = Array<Vertex<Element>>()
        var frontier: Array<Vertex<Element>> = [start]
        var expanded = Array<Vertex<Element>>()
        var cameFrom = Dictionary<String,String> ()
        var g = Dictionary<String,Int> ()
        g[start.description] = 0
        
        var f = Dictionary<String,Int> ()

        while frontier.count > 0 {
            var frontierMin = frontier[0]
            
            for fr in frontier{
                if (f[fr.description] ?? 0 < f[frontierMin.description] ?? 0){
                    frontierMin = fr
                }
            }
            
            var current = frontierMin
            
            if current == destination {
                return out
            }
            
            if let index = frontier.index(of: current) {
                frontier.remove(at: index)
            }
            expanded.append(current)
            
            for neighbor in findNeighbors(node: current) {
                if expanded.index(of: neighbor) != NSNotFound{
                    continue
                }
                if frontier.index(of: neighbor) == NSNotFound{
                    frontier.append(neighbor)
                }
                //if g[current.description]/* + distance(current,neighbor)*/ >= g[neighbor.description]  {
                //    continue
                //}
                
                cameFrom[neighbor.description] = current.description
                g[neighbor.description] = g[current.description]// + distance(current,neighbor) // Distance function takes two string (x,y,z) positions
                f[neighbor.description]  = g[neighbor.description]// + distance(neighbor,destination) // Distance function called again
            }
        }
        print("Failure")
        return Array<Vertex<Element>>()
        
    }
    
    // Returns array of neighbors
    public func findNeighbors(node: Vertex<Element>) -> Array<Vertex<Element>>{
        var neighbors = Array<Vertex<Element>>()
        
        return neighbors
    }
}
