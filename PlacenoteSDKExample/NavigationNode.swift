//
//  NavigationNode.swift
//  PlacenoteSDKExample
//
//  Created by Team Herman Miller on 1/30/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import Foundation
import SceneKit

class NavigationNode {
    var type: ShapeType
    var nodeNum: Double
    var position: SCNVector3
    var node: SCNNode
    init(number: Double, Stype: ShapeType, position: SCNVector3){
        self.type     = Stype
        self.position = position
        self.node     = SCNNode()
        self.nodeNum  = number

    }
    func getNode() -> SCNNode{
        switch self.nodeNum {
        case 1:
            return generateBreadCrumb(pos01: self.position)
        case 2:
            return generateCheckpoint(vector_pos: self.position)
        case 3:
            return generateDestination(pos01: self.position)
        default:
            return SCNNode()
        }
    }
    
    func generateBreadCrumb(pos01: SCNVector3) -> SCNNode{
        let geometry:SCNGeometry = ShapeType.generateGeometry(s_type: ShapeType.Sphere)
        geometry.materials.first?.diffuse.contents = UIColor.blue
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = pos01
        geometryNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        return geometryNode
    }
    
    func generateCheckpoint(vector_pos: SCNVector3) -> SCNNode{
        let geometry: SCNGeometry = ShapeType.generateGeometry(s_type: ShapeType.Box)
        geometry.materials.first?.diffuse.contents = UIColor.blue
        let checkpointNode = SCNNode(geometry: geometry)
        checkpointNode.position = vector_pos
        checkpointNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        return checkpointNode
    }
    
    func generateDestination(pos01: SCNVector3) -> SCNNode{
        let geometry:SCNGeometry = ShapeType.generateGeometry(s_type: ShapeType.Pyramid) //meters
        geometry.materials.first?.diffuse.contents = UIColor.lightGray
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = pos01
        geometryNode.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray
        return geometryNode
    }
    
    func toString() -> String{
        let x = NSString(format: "%.8f", self.position.x)
        let y = NSString(format: "%.8f", self.position.y)
        let z = NSString(format: "%.8f", self.position.z)
        let s3 = NSString(format:"%@,%@,%@",x,y,z)
        let resultString = s3 as String
        return resultString
    }
    
}
