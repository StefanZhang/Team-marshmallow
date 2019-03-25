//
//  ShapeManager.swift
//  Shape Dropper (Placenote SDK iOS Sample)
//
//  Created by Prasenjit Mukherjee on 2017-10-20.
//  Copyright © 2017 Vertical AI. All rights reserved.
//

import Foundation
import SceneKit

extension String {
  func appendLineToURL(fileURL: URL) throws {
    try (self + "\n").appendToURL(fileURL: fileURL)
  }
  
  func appendToURL(fileURL: URL) throws {
    let data = self.data(using: String.Encoding.utf8)!
    try data.append(fileURL: fileURL)
  }
}


extension Data {
  func append(fileURL: URL) throws {
    if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
      defer {
        fileHandle.closeFile()
      }
      fileHandle.seekToEndOfFile()
      fileHandle.write(self)
    }
    else {
      try write(to: fileURL, options: .atomic)
    }
  }
}

func generateRandomColor() -> UIColor {
  let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
  let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.3 // from 0.3 to 1.0 to stay away from white
  let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.3 // from 0.3 to 1.0 to stay away from black
  
  return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
}


//Class to manage a list of shapes to be view in Augmented Reality including spawning, managing a list and saving/retrieving from persistent memory using JSON
class ShapeManager {
  
  private var scnScene: SCNScene!
  private var scnView: SCNView!
  
  private var shapePositions: [SCNVector3] = []
  private var shapeTypes: [ShapeType] = []
  private var shapeNodes: [SCNNode] = []
  
  public var shapesDrawn: Bool! = false

    
  init(scene: SCNScene, view: SCNView) {
    scnScene = scene
    scnView = view
  }
    
  func getShapePositions() -> [SCNVector3] {
        return shapePositions
  }
    
  // Getter for Nodes object
  func getShapeNodes() -> [SCNNode] {
        return shapeNodes
  }
    
  func getShapeArray() -> [[String: [String: String]]] {
    var shapeArray: [[String: [String: String]]] = []
    if (shapePositions.count > 0) {
      for i in 0...(shapePositions.count-1) {
        shapeArray.append(["shape": ["style": "\(shapeTypes[i].rawValue)", "x": "\(shapePositions[i].x)",  "y": "\(shapePositions[i].y)",  "z": "\(shapePositions[i].z)" ]])
      }
    }
    return shapeArray
  }

  // Load shape array
    // This is where Matthew needs to get all the nodes from
  func loadShapeArray(shapeArray: [[String: [String: String]]]?) -> Bool {
    clearShapes() //clear currently viewing shapes and delete any record of them.

    if (shapeArray == nil) {
        print ("Shape Manager: No shapes for this map")
        return false
    }

    dump(shapeArray)
    
     //This is placenote originially
    for item in shapeArray! { //left off here because I'm trying to keep the same color
      let x_string: String = item["shape"]!["x"]!
      let y_string: String = item["shape"]!["y"]!
      let z_string: String = item["shape"]!["z"]!
      let position: SCNVector3 = SCNVector3(x: Float(x_string)!, y: Float(y_string)!, z: Float(z_string)!)
      let type: ShapeType = ShapeType(rawValue: Int(item["shape"]!["style"]!)!)!
      shapePositions.append(position)
      shapeTypes.append(type)
      shapeNodes.append(createShape(position: position, type: type))
      print ("Shape Manager: Retrieved " + String(describing: type) + " type at position" + String (describing: position))
    }

    
    print ("Shape Manager: retrieved " + String(shapePositions.count) + " shapes")
    return true
  }
    
  func clearView() { //clear shapes from view
    for shape in shapeNodes {
      shape.removeFromParentNode()
    }
    shapesDrawn = false
  }
  
  func drawView(parent: SCNNode) {
    guard !shapesDrawn else {return}
    for shape in shapeNodes {
      parent.addChildNode(shape)
    }
    shapesDrawn = true
  }
  
  func clearShapes() { //delete all nodes and record of all shapes
    clearView()
    for node in shapeNodes {
      node.geometry!.firstMaterial!.normal.contents = nil
      node.geometry!.firstMaterial!.diffuse.contents = nil
    }
    shapeNodes.removeAll()
    dump(String(shapeNodes.count) + " Shape Node count")
    shapePositions.removeAll()
    dump(String(shapePositions.count) + " Shape Position count")
    shapeTypes.removeAll()
    dump(String(shapeTypes.count) + " Shape types count" )
    print("Here are all the children: ")
    //
    for child in scnScene.rootNode.childNodes{
        child.removeFromParentNode()
    }
    
  }
  
  
  
  func spawnRandomShape(position: SCNVector3) {
    
    let shapeType: ShapeType = ShapeType.random()
    placeShape(position: position, type: shapeType)
  }
    
    
  func spawnNewBreadCrumb(position1: SCNVector3){
    let shapeType: ShapeType = ShapeType.Sphere
    placeCrumb(pos_1: position1, type: shapeType)
  }
    
  func spawnNewCheckpoint(position_01: SCNVector3){
    let shapeType: ShapeType = ShapeType.Box
    placeCheck(checkpoint_pos: position_01, type: shapeType)
  }
    
  func spawnNewDestination(position_1: SCNVector3){
    let shapeType: ShapeType = ShapeType.Pyramid
    placeDestination(destination_pos: position_1, type: shapeType)
  }
  

  func subtraction (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
  }
    
/*
  func generateCheckpoint(vector_pos: SCNVector3) -> SCNNode{
    let geometry: SCNGeometry =  SCNBox(width: 0.2, height: 0.3, length: 0.4, chamferRadius: 1.0)  //ShapeType.generateGeometry(s_type: ShapeType.Box)
    geometry.materials.first?.diffuse.contents = UIColor.red
    let checkpointNode = SCNNode(geometry: geometry)
    checkpointNode.position = vector_pos
    checkpointNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
    return checkpointNode
  }
    
  

//  func generateBreadCrumb(pos01: SCNVector3, pos02: SCNVector3) -> SCNNode{
//    let geometry:SCNGeometry = SCNSphere(radius: 0.1) //meters
//    geometry.materials.first?.diffuse.contents = UIColor.red
//    let geometryNode = SCNNode(geometry: geometry)
//    geometryNode.position = subtraction(left:pos01,right:pos02)
//    geometryNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
//    return geometryNode
//  }
    
    func generateBreadCrumb(pos01: SCNVector3) -> SCNNode{
        let geometry:SCNGeometry = SCNSphere(radius: 0.2) //ShapeType.generateGeometry(s_type: ShapeType.Sphere)
        geometry.materials.first?.diffuse.contents = UIColor.red
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = pos01
        geometryNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        return geometryNode
    }
    
  func generateDestination(pos01: SCNVector3) -> SCNNode{
    let geometry:SCNGeometry = SCNPyramid(width: 0.1, height: 0.3, length: 0.4)//ShapeType.generateGeometry(s_type: ShapeType.Pyramid) //meters
    geometry.materials.first?.diffuse.contents = UIColor.red
    let geometryNode = SCNNode(geometry: geometry)
    geometryNode.position = pos01
    geometryNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
    return geometryNode
    }
    
*/
  func placeCheck(checkpoint_pos: SCNVector3, type: ShapeType){
    //let boxNode: SCNNode = generateCheckpoint(vector_pos: checkpoint_pos)
    let boxNode = NavigationNode(number: 2.0, Stype: type, position: checkpoint_pos)
    shapePositions.append(boxNode.position)
    shapeTypes.append(boxNode.type)
    shapeNodes.append(boxNode.getNode())
    scnScene.rootNode.addChildNode(boxNode.getNode())
    shapesDrawn = true
  }

  func placeCrumb(pos_1: SCNVector3, type: ShapeType) {
    //let sphereNode: SCNNode = generateBreadCrumb(pos01: pos_1)
    let sphereNode = NavigationNode(number: 1.0, Stype: type, position: pos_1)
    shapePositions.append(sphereNode.position)
    shapeTypes.append(type)
    shapeNodes.append(sphereNode.getNode())
    scnScene.rootNode.addChildNode(sphereNode.getNode())
    shapesDrawn = true
    
  }
    
  func placeDestination(destination_pos: SCNVector3, type: ShapeType) {
    //let desNode: SCNNode = generateDestination(pos01: destination_pos)
    let desNode = NavigationNode(number: 3.0, Stype: type, position: destination_pos)
    shapePositions.append(desNode.position)
    shapeTypes.append(type)
    shapeNodes.append(desNode.getNode())
    scnScene.rootNode.addChildNode(desNode.getNode())
    shapesDrawn = true
        
  }
  
  func placeShape (position: SCNVector3, type: ShapeType) {
    
    let geometryNode: SCNNode = createShape(position: position, type: type)
    
    shapePositions.append(position)
    shapeTypes.append(type)
    shapeNodes.append(geometryNode)
    
    scnScene.rootNode.addChildNode(geometryNode)
    shapesDrawn = true
  }
  
  func createShape (position: SCNVector3, type: ShapeType) -> SCNNode {
    
    let geometry:SCNGeometry = ShapeType.generateGeometry(s_type: type) //might need to do this in the generate bread crumb function to retain the type
    let color = UIColor.blue
    geometry.materials.first?.diffuse.contents = color
    
    let geometryNode = SCNNode(geometry: geometry)
    geometryNode.position = position
    // Maybe this makes the loaded spheres smaller
    //geometryNode.scale = SCNVector3(x:0.1, y:0.1, z:0.1)
    
    return geometryNode
  }
  
//    func checkAdjacent(selfPos: SCNVector3) -> Bool {
//        for node in shapePositions{
//            if nodeDistance(first: selfPos, second: node) < 1.5 {
//                return true
//            }
//        }
//        return false
//    }
    
    func checkAdjacent(selfPos: SCNVector3, distance: Float) -> [SCNVector3] {
        var res = [SCNVector3]()
        for node in shapePositions{
            if nodeDistance(first: selfPos, second: node) < distance {
                res.append(node)
            }
        }
        return res
    }
    
    func nodeDistance (first: SCNVector3, second: SCNVector3) -> Float {
        let x = first.x - second.x
        let y = first.y - second.y
        let z = first.z - second.z
        return sqrt(x*x + y*y + z*z)
    }
}
