//
//  ViewControllerUM.swift
//  PlacenoteSDKExample
//
//  Created by Team Herman Miller on 3/21/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation
import PlacenoteSDK
import SceneKit

class ViewControllerUM: UIViewController, ARSCNViewDelegate, ARSessionDelegate,PNDelegate, CLLocationManagerDelegate {
    
    //Status variables to track the state of the app with respect to libPlacenote
    private var trackingStarted: Bool = false;
    private var mappingStarted: Bool = false;
    private var localizationStarted: Bool = false;
    private var reportDebug: Bool = false
    private var maxRadiusSearch: Float = 500.0 //m
    private var currRadiusSearch: Float = 0.0 //m
    private var newMapfound = false
    private var hour    = 0
    private var minutes = 0
    private var seconds = 0
    private var maxSizeReached = false
    
    //Information passed from WT and WAY
    var destination : [String] = []
    var initialLocation : [String] = []
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // For PNDelegate function
    func onPose(_ outputPose: matrix_float4x4, _ arkitPose: matrix_float4x4) -> Void {
    }
    
    func onStatusChange(_ prevStatus: LibPlacenote.MappingStatus, _ currStatus: LibPlacenote.MappingStatus) {
        
        if prevStatus != LibPlacenote.MappingStatus.running && currStatus == LibPlacenote.MappingStatus.running { //just localized draw shapes you've retrieved
            print ("Just localized, drawing view")
            shapeManager.drawView(parent: userScene.rootNode) //just localized redraw the shapes
            if mappingStarted {
                hour = calendar.component(.hour, from: date)
                minutes = calendar.component(.minute, from: date)
                seconds = calendar.component(.second, from: date)
                self.newMapfound = false
                userLabel.text = "Move Slowly And Stay Within 3 Feet Of Features"
            }
            else if localizationStarted {
                userLabel.text = "Map Found!"
            }
            
            //As you are localized, the camera has been moved to match that of Placenote's Map. Transform the planes
            //currently being drawn from the arkit frame of reference to the Placenote map's frame of reference.
        }
        
        if prevStatus == LibPlacenote.MappingStatus.running && currStatus != LibPlacenote.MappingStatus.running { //just lost localization
            print ("Just lost")
            if mappingStarted {
                userLabel.text = "Moved too fast. Map Lost"
            }
            
        }
        
    }
    

    @IBOutlet var userView: ARSCNView!
    private var userScene: SCNScene!
    
    private var shapeManager: ShapeManager!
    @IBOutlet weak var userLabel: UILabel!
    
    private var locationManager: CLLocationManager!
    private var lastLocation: CLLocation? = nil
    
    //Variables to manage PlacenoteSDK features and helpers
    private var maps: [(String, LibPlacenote.MapMetadata)] = [("Sample Map", LibPlacenote.MapMetadata())]
    private var camManager: CameraManager? = nil;
    private var ptViz: FeaturePointVisualizer? = nil;
    
    private var planesVizAnchors = [ARAnchor]();
    private var planesVizNodes = [UUID: SCNNode]();
    
    private var graph  = AdjacencyList<String>()
    private var mapStack = [Vertex<String>]()
    //let desination = ViewControllerWT.getSelectedPlace(ViewControllerWT)

    override func viewDidLoad() {
        super.viewDidLoad()
        userView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        
        userView = self.view as! ARSCNView
        userView.delegate = self
        userView.session.delegate = self as! ARSessionDelegate
        userView.isPlaying = true
        
        userScene = SCNScene()
        userView.scene = userScene
        ptViz = FeaturePointVisualizer(inputScene: userScene);
        ptViz?.enableFeaturePoints()
        
        if let camera: SCNNode = userView?.pointOfView {
            camManager = CameraManager(scene: userScene, cam: camera)
        }
        
        shapeManager = ShapeManager(scene: userScene, view: userView)
        LibPlacenote.instance.multiDelegate += self;
        
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self;
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager.startUpdatingLocation()
        }
    }
    

    //Initialize view and scene
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureSession();
        
    }
    
    func configureSession() {
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = ARWorldTrackingConfiguration.WorldAlignment.gravity
        
        userView.session.run(config)
    }
    

    func getVertexByLoc (mapLoc:String) -> Vertex<String> {
        for vertex in appDelegate.allVertices {
            if (vertex.description == mapLoc) {
                return vertex
            }
        }
        return Vertex<String>(loc: "0")
    }
    
    @IBAction func loadMapButton(_ sender: Any) {
        //print("This is graph info")
        //dump(appDelegate.allVertices)
        //dump(appDelegate.ultimateGraph)
//
        let desMapName = destination[0]
        let initMapName = initialLocation[0]
        let desMapLoc = appDelegate.MapLocationDict[desMapName]
        let initMapLoc = appDelegate.MapLocationDict[initMapName]
        
        let desVertex = getVertexByLoc(mapLoc: desMapLoc!)
        let initVertex = getVertexByLoc(mapLoc: initMapLoc!)
        
        mapStack = appDelegate.aStarForMaps(start: initVertex, destination: desVertex)

        maps = appDelegate.maps
        
        if (!mapStack.isEmpty){
            userLabel.text = "Loading Map"
            
            var mapIDs = [String]()
            var mapIndexArray = [Int]()
            // For every map in the mapStack, find its mapID
            for mapToLoad in mapStack {
                var mapIndex = 0
                for map in maps {
                    let str = mapLocToString(lat: (map.1.location?.latitude)!, lon: (map.1.location?.longitude)!, alt: (map.1.location?.altitude)!)
                    if (str == mapToLoad.description) {
                        mapIDs.append(map.0)
                        mapIndexArray.append(mapIndex)
                        break
                    }
                    mapIndex += 1
                }
            }
//            dump(maps)
//            dump(mapIDs)
//            dump(mapIndexArray)
            
            let length = mapIDs.count
            for indexPath in 0..<length {

                LibPlacenote.instance.loadMap(mapId: mapIDs[indexPath],
                                              downloadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                                                if (completed) {

                                                    //Use metadata acquired from fetchMapList
                                                    let userdata = self.maps[indexPath].1.userdata as? [String:Any]
                                                    
                                                    if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                                        self.userLabel.text = "Map Loaded. Look Around"
                                                    }
                                                    else {
                                                        self.userLabel.text = "Map Loaded. Shape file not found"
                                                    }
                                                    LibPlacenote.instance.startSession(extend: true)


                                                    
                                                } else if (faulted) {
                                                    print ("Couldnt load map: " + self.maps[indexPath].0)
                                                    self.userLabel.text = "Load error Map Id: " +  self.maps[indexPath].0
                                                } else {
                                                    print ("Progress: " + percentage.description)
                                                }
                }
                )
            }
        }
        
        
    }
    
   
    
    func mapLocToString(lat: Double, lon: Double, alt: Double) -> String{
        let x = NSString(format: "%.16f", lat)
        let y = NSString(format: "%.16f", lon)
        let z = NSString(format: "%.16f", alt)
        let s3 = NSString(format:"%@,%@,%@",x,y,z)
        let resultString = s3 as String
        return resultString
    }
    
    @IBAction func showPathButton(_ sender: Any) {
    }
}
