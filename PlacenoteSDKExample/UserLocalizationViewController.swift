//
//  UserLocalizationViewController.swift
//  PlacenoteSDKExample
//
//  Created by Team Herman Miller on 2/20/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import PlacenoteSDK

class UserLocalizationViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate{

    @IBOutlet var navView: ARSCNView!
    
    //AR Scene
    private var navScene: SCNScene!
    
    private var camManager: CameraManager? = nil;
    private var ptViz: FeaturePointVisualizer? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
    }
    
    //Initialize view and scene
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureSession();
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        navView.session.pause()
    }
    
    //Function to setup the view and setup the AR Scene including options
    func setupView() {
        navView = self.view as! ARSCNView
        navView.showsStatistics = true
        navView.autoenablesDefaultLighting = true
        navView.delegate = self
        navView.session.delegate = self
        navView.isPlaying = true
        navView.debugOptions = []
        //hide the radius search UI, reset values as we are initializating
        //navView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        //navView.debugOptions = ARSCNDebugOptions.showWorldOrigin
    }
    
    //Function to setup AR Scene
    func setupScene() {
        navScene = SCNScene()
        navView.scene = navScene
        ptViz = FeaturePointVisualizer(inputScene: navScene);
        ptViz?.enableFeaturePoints()
        
        if let camera: SCNNode = navView?.pointOfView {
            camManager = CameraManager(scene: navScene, cam: camera)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navView.frame = view.bounds
    }
    
    
    // MARK: - PNDelegate functions
    
    //Receive a pose update when a new pose is calculated
    func onPose(_ outputPose: matrix_float4x4, _ arkitPose: matrix_float4x4) -> Void {
        
    }
    
    func configureSession() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = ARWorldTrackingConfiguration.WorldAlignment.gravity //TODO: Maybe not heading?
        
 
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        } else {
            configuration.planeDetection = [.horizontal]
        }
        
        // Run the view's session
        navView.session.run(configuration)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
