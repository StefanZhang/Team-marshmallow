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
            //dump(edge.destination.description)
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
    
    public func reconstructPath(cameFrom: Dictionary<String,Vertex<Element>>, currentVertex:Vertex<Element>) -> Array<Vertex<Element>> {
        var current = currentVertex
        var total_path = [current]
        while (cameFrom[current.description] != nil) {
            current = cameFrom[current.description]!
            total_path.append(current)
        }
        return total_path
    }
    public func aStar(start: Vertex<Element>, destination: Vertex<Element>) -> Array<Vertex<Element>>{
        
        // Dictonary in graph
        let graphDict = adjacencyDict
        
        // arrays of coordinate strings
        var keyStrs = [String]()
        for vertex in graphDict.keys {
            keyStrs.append(vertex.description)
        }
        
        // The set of nodes already evaluated
        // closedSet := {}
        var out = Array<Vertex<Element>>()
        
        // The set of currently discovered nodes that are not evaluated yet.
        // Initially, only the start node is known.
        //openSet := {start}
        var frontier: Array<Vertex<Element>> = [start]
        
        // hmm?
        //var expanded = Array<Vertex<Element>>()
        
        // For each node, which node it can most efficiently be reached from.
        // If a node can be reached from many nodes, cameFrom will eventually contain the
        // most efficient previous step.
        var cameFrom = Dictionary<String,Vertex<Element>> ()
        
        // For each node, the cost of getting from the start node to that node.
        // gScore := map with default value of Infinity
        //
        var g = Dictionary<String,Double> ()
        for str in keyStrs {
            g[str] = Double.infinity
        }
        // The cost of going from start to start is zero.
        g[start.description] = 0.0
        
//        print("This is dictionary g")
//        print(g)
        
//        print("This should be the string")
//        print(start.description)
        
        // For each node, the total cost of getting from the start node to the goal
        // by passing by that node. That value is partly known, partly heuristic.
        // fScore := map with default value of Infinity
        var f = Dictionary<String,Double> ()
        for str in keyStrs {
            f[str] = Double.infinity
        }
        
        // For the first node, that value is completely heuristic.
        // fScore[start] := heuristic_cost_estimate(start, goal)
        // hmm?
        f[start.description] = 1000
        
        
        while frontier.count > 0 {
            
            // current := the node in openSet having the lowest fScore[] value
            // current is vertex type
            var frontierMin = frontier[0]
            for fr in frontier{
                if (f[fr.description] ?? 0 < f[frontierMin.description] ?? 0){
                    frontierMin = fr
                }
            }
            let current = frontierMin
            
            
            //if current = goal
            if current == destination {
                //return reconstruct_path(cameFrom, current)
                print("Final G score dictionary")
                print(g)
                return reconstructPath(cameFrom: cameFrom, currentVertex: current)
//                //For testing
//                var endCurrent = current
//                while cameFrom.keys.contains(endCurrent.description) {
//                    endCurrent = cameFrom[endCurrent.description]!
//                    out.append(endCurrent)
//                }
//                //
//
//                return out
            }
            
            //openSet.Remove(current)
            let currentIndex = frontier.firstIndex(of: current)
            frontier.remove(at: currentIndex!)
            //closedSet.Add(current)
            out.append(current)
            
//            // Remove current node from frontier
//            if let index = frontier.index(of: current) {
//                frontier.remove(at: index)
//            }
//            // Add to expanded nodes
//            expanded.append(current)
            
//            print("These are the neighbors of current")
//            dump(findNeighbors(node: current))
            
            for neighbor in findNeighbors(node: current) {
//                print("This is the first neighbor of current")
//                dump(neighbor)
                
                //if neighbor in closedSet(Out)
                //continue
                // Ignore the neighbor which is already evaluated.
                if out.contains(neighbor){
                    continue
                }
                
                // The distance from start to a neighbor
                // tentative_gScore := gScore[current] + dist_between(current, neighbor)
                let tentative_gScore = g[current.description]! + distance(first: current.description, second: neighbor.description)
                
                print("This is tentative distance from start to a neighbor")
                print(tentative_gScore)
                
                //if neighbor not in openSet    // Discover a new node
                //openSet.Add(neighbor)
                
                if !frontier.contains(neighbor) {
                    frontier.append(neighbor)
                }
                else if (tentative_gScore >= g[neighbor.description]!) {
                    continue
                }
                
                cameFrom[neighbor.description] = current
                g[neighbor.description] = tentative_gScore
                f[neighbor.description] = g[neighbor.description]! + distance(first: neighbor.description,second: destination.description)
                
                /*
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
                */
            }
        }
        print("Failure")
        return Array<Vertex<Element>>()
        
    }

}

