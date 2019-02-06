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
    
    // Returns array of neighbors
    public func findNeighbors(node: Vertex<Element>) -> Array<Vertex<Element>> {
        var neighbors = Array<Vertex<Element>>()
        let edge_list = edges(from: node)
        for edge in edge_list! {
            dump(edge.destination.description)
            neighbors.append(edge.destination)
        }
        return neighbors
    }
    
    func distance (first: String, second: String) -> Double {
        let strArray = first.split(separator: ",")
        let strArray2 = second.split(separator: ",")
        let x1 = Double(strArray[0]) ?? 0.0
        let y1 = Double(strArray[1]) ?? 0.0
        let z1 = Double(strArray[2]) ?? 0.0
        let x2 = Double(strArray2[0]) ?? 0.0
        let y2 = Double(strArray2[1]) ?? 0.0
        let z2 = Double(strArray2[2]) ?? 0.0

        let x = x1 - x2
        let y = y1 - y2
        let z = z1 - z2
        return sqrt(x*x + y*y + z*z)
    }
    
    public func aStar(start: Vertex<Element>, destination: Vertex<Element>) -> Array<Vertex<Element>>{
        var out = Array<Vertex<Element>>()
        var frontier: Array<Vertex<Element>> = [start]
        var expanded = Array<Vertex<Element>>()
        var cameFrom = Dictionary<String,Vertex<Element>> ()
        var g = Dictionary<String,Double> ()
        g[start.description] = 0.0
        
        print("This should be the string")
        print(start.description)
        
        var f = Dictionary<String,Double> ()

        while frontier.count > 0 {
            var frontierMin = frontier[0]
            
            for fr in frontier{
                if (f[fr.description] ?? 0 < f[frontierMin.description] ?? 0){
                    frontierMin = fr
                }
            }
            
            let current = frontierMin
            
            if current == destination {
                
                //For testing
                var endCurrent = current
                while cameFrom.keys.contains(endCurrent.description) {
                    endCurrent = cameFrom[endCurrent.description]!
                    out.append(endCurrent)
                }
                //
                
                return out
            }
            // Remove current node from frontier
            if let index = frontier.index(of: current) {
                frontier.remove(at: index)
            }
            // Add to expanded nodes
            expanded.append(current)
            
            for neighbor in findNeighbors(node: current) {
                if expanded.index(of: neighbor) != NSNotFound{
                    continue
                }
                if frontier.index(of: neighbor) == NSNotFound{
                    frontier.append(neighbor)
                }
                if (g[current.description] ?? 0.0 + distance(first: current.description,second: neighbor.description)) >= (g[neighbor.description] ?? Double(1000000) ){
                    continue
                }
                // Testing
                print("DISTANCE")
                print(distance(first: current.description,second: neighbor.description))
                print(distance(first: current.description,second: destination.description))
                
                //
                
                cameFrom[neighbor.description] = current
                g[neighbor.description] = g[current.description] ?? 0.0 + distance(first: current.description,second: neighbor.description) // Distance function takes two string (x,y,z) positions
                f[neighbor.description]  = g[neighbor.description] ?? 0.0 + distance(first: neighbor.description,second: destination.description) // Distance function called again
            }
        }
        print("Failure")
        return Array<Vertex<Element>>()
        
    }
    

}

