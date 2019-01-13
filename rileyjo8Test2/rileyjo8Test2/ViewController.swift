//
//  ViewController.swift
//  rileyjo8Test2
//
//  Created by Team Herman Miller on 1/12/19.
//  Copyright © 2019 Team Herman Miller. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // sets up session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // runs it, augmented reality tracking, allows for surface detection
        sceneView.session.run(configuration)
        
    }
    
    func randomFloat(min: Float, max: Float) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }

    @IBAction func addCube(_ sender: Any) {
        //let zCoords = randomFloat(min: -2, max: -0.2)
        var cubeNode = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
        //cubeNode.position = SCNVector3(0,0,zCoords) // places cube 20cm in front of our face
        let cc = getCameraCoordinates(sceneView: sceneView)
        cubeNode.position = SCNVector3(cc.x, cc.y, cc.z)
        sceneView.scene.rootNode.addChildNode(cubeNode)
    }
    
    @IBAction func addCup(_ sender: Any) {
        let cupNode = SCNNode()
        let cc = getCameraCoordinates(sceneView: sceneView) // in relation to root node based off camera coordinates
        cupNode.position = SCNVector3(cc.x, cc.y, cc.z)     // places cupNode at the position of the camera
        
        guard let virtualObjectScene = SCNScene(named: "cup.scn", inDirectory: "Models.scnassets/cup")
            else{
                return
        }
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes{
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            wrapperNode.addChildNode(child)
        }
        cupNode.addChildNode(wrapperNode)
        sceneView.scene.rootNode.addChildNode(cupNode)
    }
    
    struct myCameraCoords{
        var x = Float()
        var y = Float()
        var z = Float()
    }
    
    func getCameraCoordinates(sceneView: ARSCNView) -> myCameraCoords{
        let cameraTransform = sceneView.session.currentFrame?.camera.transform
        let cameraCoords = MDLTransform(matrix: cameraTransform!)
        var cc = myCameraCoords()
        cc.x = cameraCoords.translation.x
        cc.y = cameraCoords.translation.y
        cc.z = cameraCoords.translation.z
        return cc
    }
    
}

