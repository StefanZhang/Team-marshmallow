//
//  ViewController.swift
//  rileyjo8Test
//
//  Created by Team Herman Miller on 1/12/19.
//  Copyright © 2019 Team Herman Miller. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        //_____________________________________________________________________________________________________
        
        // Sets text and specifies thickness of it
        let text = SCNText(string: "Herman Miller, AAron", extrusionDepth: 1)
        
        let material = SCNMaterial()                // creates material object
        material.diffuse.contents = UIColor.red     // sets to red color
        text.materials = [material]                 // assigns material to text
        
        let node = SCNNode()
        node.position = SCNVector3(x:0,y:0.02,z:-0.1)   // sets position of node
        node.scale = SCNVector3(x:0.01,y:0.01,z:0.01)   // scales object to 10 cm
        node.geometry = text                            // sets text geometry to node object
        
        sceneView.scene.rootNode.addChildNode(node)     // adds node to scene view

        sceneView.autoenablesDefaultLighting = true     // adds shadows
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
