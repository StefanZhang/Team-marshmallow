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
    
    //Zhenru
    var newNodes = [SCNNode]()
    
    //Information passed from WT and WAY
    // First element is mapName, second element is V3
    var destination : [String] = []
    var initialLocation : [String] = []
    
    var startStr = ""
    var desStr = ""
    
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
            for (_, node) in planesVizNodes {
                node.transform = LibPlacenote.instance.processPose(pose: node.transform);

            }
            
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
    
    private var looking = false
    private var planesVizAnchors = [ARAnchor]();
    private var planesVizNodes = [UUID: SCNNode]();
    
    private var graph  = AdjacencyList<String>()
    private var mapStack = [Vertex<String>]()
    
    
    //let desination = ViewControllerWT.getSelectedPlace(ViewControllerWT)
    
    var mapDataStack = [(String,LibPlacenote.MapMetadata)]()
    var indexPath = 0
    
    var CheckpointV3 = [String]()
    var CheckpointCoreLoc = [String]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        setupView()
        setupScene()
        
        shapeManager = ShapeManager(scene: userScene, view: userView)
        LibPlacenote.instance.multiDelegate += self;
        
        desStr = destination[1]
        startStr = initialLocation[1]
        
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self;
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager.startUpdatingLocation()
        }
    }
    
    //Function to setup the view and setup the AR Scene including options
    func setupView() {
        userView = self.view as! ARSCNView
        userView.showsStatistics = false
        userView.autoenablesDefaultLighting = true
        userView.delegate = self
        userView.session.delegate = self
        userView.isPlaying = true
        userView.debugOptions = []
        //hide the radius search UI, reset values as we are initializating
        //userView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        //userView.debugOptions = ARSCNDebugOptions.showWorldOrigin
    }
    
    //Function to setup AR Scene
    func setupScene() {
        userScene = SCNScene()
        userView.scene = userScene
        ptViz = FeaturePointVisualizer(inputScene: userScene);
        ptViz?.enableFeaturePoints()
        
        if let camera: SCNNode = userView?.pointOfView {
            camManager = CameraManager(scene: userScene, cam: camera)
        }
    }

    //Initialize view and scene
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureSession();
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        userView.session.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        userView.frame = view.bounds
    }
    
    func configureSession() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = ARWorldTrackingConfiguration.WorldAlignment.gravity //TODO: Maybe not heading?
        
        
        // Run the view's session
        userView.session.run(configuration)
    }
    

    func getVertexByLoc (mapLoc:String) -> Vertex<String> {
        for vertex in appDelegate.allVertices {
            if (vertex.description == mapLoc) {
                return vertex
            }
        }
        return Vertex<String>(loc: "0")
    }
    
    func findClosestBC(camV3: SCNVector3) -> String {
        let camStr = SCNV3toString(vec: camV3)
        for shapePosition in shapeManager.getShapePositions() {
            if (camStr == SCNV3toString(vec: shapePosition)){
                return SCNV3toString(vec: shapePosition)
            }
            
        }
        return ""
    }
    
    @IBAction func loadMapButton(_ sender: Any) {
        //print("This is graph info")
        //dump(appDelegate.allVertices)
        //dump(appDelegate.ultimateGraph)
//
        //dump(destination)
        //dump(initialLocation)
        
        let desMapName = destination[0]
        let initMapName = initialLocation[0]
        dump("des and init map name")
        dump(desMapName)
        dump(initMapName)
        
        let desMapLoc = appDelegate.MapLocationDict[desMapName]
        let initMapLoc = appDelegate.MapLocationDict[initMapName]
        
        let desVertex = getVertexByLoc(mapLoc: desMapLoc!)
        let initVertex = getVertexByLoc(mapLoc: initMapLoc!)
        
        // array of locations of maps
        
        mapStack = appDelegate.aStarForMaps(start: initVertex, destination: desVertex)
        dump(mapStack) // This is giving end and start map
        
        if (mapStack.count == 2) {
            let temp = mapStack[1]
            mapStack[1] = mapStack[0]
            mapStack[0] = temp
        }
        
        dump(mapStack)
        maps = appDelegate.maps
        
        if (!mapStack.isEmpty){
            userLabel.text = "Loading Map"
            
            var mapIDs = [String]()
            var mapIndexArray = [Int]()
            
            // For every map in the mapStack, find its mapID
            let mapLocsFloat = appDelegate.pathOrder(custommaps: maps)
            for mapToLoad in mapStack {
                var mapIndex = 0
                for map in maps {
                    let str = mapLocToString(lat: mapLocsFloat[0][mapIndex], lon: mapLocsFloat[1][mapIndex])
                    if (str == mapToLoad.description) {
                        mapIDs.append(map.0)
                        mapIndexArray.append(mapIndex)
                        mapDataStack.append(map)
                        break
                    }
                    mapIndex += 1
                }
            }
            //dump(mapDataStack)
            dump(mapIDs)
            //dump(mapIndexArray)
            
            let length = mapIDs.count
            if (length > 1 ) {
                // when there are more than one map to load, i.e. des and initloc are in different maps, then find checkpoint inside the first map
                
            }
            
            let id = mapIDs[indexPath]
            LibPlacenote.instance.loadMap(mapId: id,
                                          downloadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                                            if (completed) {
                                                self.mappingStarted = true
                                                self.localizationStarted = true
                                                
                                                //Use metadata acquired from fetchMapList
                                                print("This is map data")
                                                dump(self.mapDataStack[self.indexPath])
                                                let mapdata = self.mapDataStack[self.indexPath]
                                                let userdata = mapdata.1.userdata as? [String:Any]
                                                
                                                if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                                    self.userLabel.text = "Map Loaded. Look Around" + String(length) + String(self.indexPath)
                                                    self.looking = true
                                                    self.indexPath += 1
//                                                    print("This is checkpoint info")
//                                                    dump(userdata?["CheckpointV3"])
//                                                    dump(userdata?["CheckpointCoreLoc"])
//                                                    dump(userdata?["destinationDict"])
                                                    if (self.indexPath != 0) {
                                                        // if not the initial location map, then the startStr should be the first shape you see in the map
                                                        // self.startStr = self.findClosestBC()
                                                    }
                                                    if (userdata?["CheckpointV3"] != nil && userdata?["CheckpointCoreLoc"] != nil && self.destination[0] != self.initialLocation[0]) {
                                                        self.CheckpointCoreLoc = userdata?["CheckpointCoreLoc"] as! [String]
                                                        self.CheckpointV3 = userdata?["CheckpointV3"]  as! [String]
                                                        let bestCPV3 = self.findCorrectCheckpoint(CpV3: userdata?["CheckpointV3"] as! [String], CpCL: userdata?["CheckpointCoreLoc"] as! [String], MapToLoad:mapdata)
                                                        self.desStr = self.SCNV3toString(vec: bestCPV3)
                                                    }
                                                    else {
                                                        self.userLabel.text = "The map does not contain Checkpoints"
                                                    }
                                                    
                                                }
                                                else {
                                                    self.userLabel.text = "Map Loaded. Shape file not found"
                                                }
                                                LibPlacenote.instance.startSession(extend: true)


                                                
                                            } else if (faulted) {
                                                print ("Couldnt load map: " + self.maps[self.indexPath].0)
                                                self.userLabel.text = "Load error Map Id: " +  self.maps[self.indexPath].0
                                            } else {
                                                print ("Progress: " + percentage.description)
                                            }
            }
            )
            
        }
        
        
    }
    
    func findCorrectCheckpoint(CpV3: [String], CpCL: [String], MapToLoad: (String,LibPlacenote.MapMetadata) ) -> SCNVector3 {
        var minDistance = 1000.0
        var resCpV3Str = ""
        for i in 0..<CpCL.count {
            let cp = CpCL[i]
            let cpLocation = CLLocation(latitude: Double(cp.split(separator: ",")[0])!, longitude: Double(cp.split(separator: ",")[1])!)

//            dump(cpLocation) //8 digits after decimal
            let mapLoaction = CLLocation(latitude: (MapToLoad.1.location?.latitude)!, longitude: (MapToLoad.1.location?.longitude)!)

//            let lat1 = Float(cp.split(separator: ",")[0])
//            let long1 = Float(cp.split(separator: ",")[1])
//
//            let lat2 = MapToLoad.1.location?.latitude
//            let long2 = MapToLoad.1.location?.longitude
            
            //DistanceForCL(lat1: lat1!, long1: long1!, lat2: Float(lat2!), long2: Float(long2!))
            let dis = cpLocation.distance(from: mapLoaction)
            //dump(dis)
            if (dis < minDistance) {
                minDistance = dis
                resCpV3Str = CpV3[i]
            }
        }
        if (resCpV3Str != "" ) {
            let x = Double(resCpV3Str.split(separator: ",")[0])
            let y = Double(resCpV3Str.split(separator: ",")[1])
            let z = Double(resCpV3Str.split(separator: ",")[2])
            let result = SCNVector3(x!,y!,z!)
            return result
        }
        return SCNVector3(0,0,0)
    }
    
    func DistanceForCL (lat1: Float, long1: Float, lat2: Float, long2: Float){
        let pi = Float.pi
        
        let dLat = (lat2-lat1) * pi / 180
        let dLon = (long2-long1) * pi / 180
        
        let lat3 = lat1 * pi / 180
        let lat4 = lat2 * pi / 180
        
        let a = sin(dLat/2) * sin(dLat/2) + sin(dLon/2) * sin(dLon/2) * cos(lat3) * cos(lat4)
        let c = 2 * atan2f(sqrtf(a), sqrtf(1-a))
        
        dump(6371008 * c)
    }
    
    func mapLocToString(lat: Float, lon: Float) -> String{
        let x = NSString(format: "%.16f", lat)
        let y = NSString(format: "%.16f", lon)
        
        let s3 = NSString(format:"%@,%@",x,y)
        let resultString = s3 as String
        return resultString
    }
    
    func StringToV3 (str: String) -> SCNVector3 {
        let x = Float( str.split(separator: ",")[0] )
        let y = Float( str.split(separator: ",")[1] )
        let z = Float( str.split(separator: ",")[2] )
        return SCNVector3(x!,y!,z!)
    }
    
    @IBAction func showPathButton(_ sender: Any) {
        shapeManager.clearView()
        var graph = AdjacencyList<String>()
        let shapePositions = shapeManager.getShapePositions()
        //let shapeNodes = shapeManager.getShapeNodes()
        
        graph = updateGraph(graph: graph)
        //dump(graph)
        
        let dict = graph.adjacencyDict
        let vertices = dict.keys
        
        if (!shapePositions.isEmpty && !vertices.isEmpty){
//            let start = shapePositions[0] // type V3
//            //let start = nearestShapes[0] // type V3
//            let startStr = SCNV3toString(vec: start)
//
//            let des = shapePositions[shapePositions.count-1] // type V3
//            let desStr = SCNV3toString(vec: des)
            
            //let startStr = initialLocation[1]
            //let start = StringToV3(str: startStr) // type V3
            
            //let desStr = destination[1]
            //let des = StringToV3(str: desStr) // V3
            
            var startVer = vertices.first
            var desVer = vertices.first
            
            for vertex in vertices{
                if startStr == vertex.description {
                    startVer = vertex
                }
                if desStr == vertex.description {
                    desVer = vertex
                }
            }
            
            let OutVer = graph.aStar(start: startVer!, destination: desVer!)
            var selectedPos = [SCNVector3]()
            for ver in OutVer {
                for str in shapePositions {
                    if ver.description == SCNV3toString(vec: str) {
                        selectedPos.append(str)
                    }
                }
            }
            
            print("Selected Postions:")
            print(selectedPos)
            for pos in selectedPos {
                shapeManager.spawnNewBreadCrumb(position1: pos)
            }
            
        }
        
        
    }
    
    func updateGraph (graph: AdjacencyList<String>) -> AdjacencyList<String> {
        // load the position from breadcrums
        let shapePositions = shapeManager.getShapePositions()
        let shapeNodes = shapeManager.getShapeNodes()
        
        let distance = Float(2)
        let length = shapePositions.count
        if (length > 1){
            
            for i in 0..<length { // pos is Vector3
                for j in i+1..<length{
                    if (nodeDistance(first: shapePositions[i], second: shapePositions[j]) < distance && nodeDistance(first: shapePositions[i], second: shapePositions[j]) > 0.0001) {
                        
                        let str1 = SCNV3toString(vec: shapePositions[i])
                        let str2 = SCNV3toString(vec: shapePositions[j])
                        let vertex1Array = graph.checkVertex(loc: str1)
                        let vertex2Array = graph.checkVertex(loc: str2)
                        
                        var v1 = Vertex(loc: "0")
                        var v2 = Vertex(loc: "0")
                        
                        // Checking if graph already have these vertex
                        if (!vertex1Array.isEmpty) {
                            v1 = vertex1Array[0]
                        }
                        else{
                            v1 = graph.createVertex(data: str1)
                            Hash_Node_Dict[str1] = shapeNodes[i]
                        }
                        
                        if (!vertex2Array.isEmpty) {
                            v2 = vertex2Array[0]
                        }
                        else{
                            v2 = graph.createVertex(data: str2)
                            Hash_Node_Dict[str2] = shapeNodes[j]
                        }
                        // make vertices connected
                        graph.add(.undirected, from: v1, to: v2, weight: 1.5)
                    }
                }
                
            }
        }
        
        return graph
    }
    
    func nodeDistance (first: SCNVector3, second: SCNVector3) -> Float {
        let x = first.x - second.x
        let y = first.y - second.y
        let z = first.z - second.z
        return sqrt(x*x + y*y + z*z)
    }
    
    func SCNV3toString(vec: SCNVector3) -> String{
        let x = NSString(format: "%.8f", vec.x)
        let y = NSString(format: "%.8f", vec.y)
        let z = NSString(format: "%.8f", vec.z)
        let s3 = NSString(format:"%@,%@,%@",x,y,z)
        let resultString = s3 as String
        return resultString
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }


    // MARK: - ARSessionDelegate
    func getClosetNode(camera_pos: SCNVector3, map: AdjacencyList<String>) -> Bool{
        if shapeManager.getShapePositions().count > 0 {
            for node in shapeManager.getShapeNodes()
            {
                let tre = node.geometry?.description
                if(tre != nil)
                {
                    let T = Array(tre!)[4]
                    if( T == "B") // Then this node is the checkpoint
                    {
                        let pose = LibPlacenote.instance.processPosition(pose: camera_pos)
                        // This processPosition only works if mappingStatus is running
                        
//                        print("This is distance")
//                        dump(camera_pos)
//                        dump(pose)
//                        dump(nodeDistance(first: pose, second: node.position ) )

                        if (nodeDistance(first: pose, second: node.position ) < 2)
                        {
                            let alert = UIAlertController(title: "Alert", message: "At checkpoint", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                                switch action.style{
                                case .default:
                                    print("default")
                                    
                                case .cancel:
                                    print("cancel")
                                    
                                case .destructive:
                                    print("destructive")
                                    
                                    
                                }}))
                            self.present(alert, animated: true, completion: nil)
                            self.looking = false
                            return true
                        }
                    }
                    
                }
                
            }
        }
        return false
    }
//modified this function to work with the findmap
func mapLoading(map: [(String, LibPlacenote.MapMetadata)], index: Int) -> Void //changed map to maps
  {
    userLabel.text = "Loading Map"
    LibPlacenote.instance.loadMap(mapId: map[index].0, //changed maps to self.maps
                                  downloadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                                    if (completed) {
                                      self.mappingStarted = true //extending the map
                                      self.localizationStarted = true
                                      
                                      
                                      //Using this method you can individual retrieve the metadata for a single map,
                                      //However, as we called a blanket fetchMapList before, it already acquired all the metadata for all maps
                                      //We'll just use that meta data for now.
                                      
                                      /*LibPlacenote.instance.getMapMetadata(mapId: self.maps[indexPath.row].0, getMetadataCb: {(success: Bool, metadata: LibPlacenote.MapMetadata) -> Void in
                                       let userdata = self.maps[indexPath.row].1.userdata as? [String:Any]
                                       if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                       self.statusLabel.text = "Map Loaded. Look Around"
                                       } else {
                                       self.statusLabel.text = "Map Loaded. Shape file not found"
                                       }
                                       LibPlacenote.instance.startSession(extend: true)
                                       })*/
                                      
                                      //Use metadata acquired from fetchMapList
                                      let userdata = map[index].1.userdata as? [String:Any] //maps to self.maps
                                      // This is placenote originally
                                      //                                      if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                      //                                        self.statusLabel.text = "Map Loaded. Look Around"
                                      //                                      }
                                      
                                      if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                        self.userLabel.text = "Map Loaded. Look Around"
                                        //dump(userdata?["CheckpointDict"] as? [String:String])
                                        
                                      }
                                      else {
                                        self.userLabel.text = "Map Loaded. Shape file not found"
                                      }
                                      LibPlacenote.instance.startSession(extend: true)
                                      
                                      
                                      
                                      //self.tapRecognizer?.isEnabled = true
                                    } else if (faulted) {
                                      print ("Couldnt load map: " + map[index].0)
                                      self.userLabel.text = "Load error Map Id: " +  map[index].0
                                    } else {
                                      print ("Progress: " + percentage.description)
                                    }
    }
    )
    
  }
    
    func findMap() -> ((String, LibPlacenote.MapMetadata), Int)
    {
        let locManager = CLLocationManager()
        locManager.requestWhenInUseAuthorization()
        var currentLocation: CLLocation!
        
        if( CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() ==  .authorizedAlways){
            
            currentLocation = locManager.location
            
        }
        var distance = 100.00
        let x1 = currentLocation.coordinate.longitude
        let y1 = currentLocation.coordinate.latitude
        var nextMap = self.maps[0]
        var counter = 0
        var index = 0
        for map in self.maps
        {
            
            let x2 = map.1.location?.longitude
            let y2 = map.1.location?.latitude
            if x2 != nil
            {
                let xDistance = x2! - x1
                let yDistance = y2! - y1
                
                if sqrt(xDistance * xDistance + yDistance * yDistance) < distance
                {
                    distance = sqrt(xDistance * xDistance + yDistance * yDistance)
                    nextMap = map
                    index = counter
                }
            }
            counter = counter + 1
        }
        return (nextMap, index)
    }
    
    //Provides a newly captured camera image and accompanying AR information to the delegate.
    func session(_ session: ARSession, didUpdate: ARFrame) {
        let image: CVPixelBuffer = didUpdate.capturedImage
        let pose: matrix_float4x4 = didUpdate.camera.transform
        // Gets the current amount of feature points in a frame
        let camLoc = SCNVector3(pose.columns.3.x,pose.columns.3.y,pose.columns.3.z)
//        dump(looking)
//        print("Start")
//        dump(camLoc)
//        dump(userScene.rootNode.position)
//        dump(userScene.rootNode.worldPosition)
        
        if( looking == true ){
              if (getClosetNode(camera_pos: camLoc, map: graph))
              {
                if (mapDataStack.count >= 1) {
                    
//                    let bestMap = findMap()
                    shapeManager.clearShapes()
//                    mapLoading(maps: [bestMap.0], index: bestMap.1)
                    mapLoading(map: mapDataStack, index: indexPath )
                }
              }
        }
        if (!LibPlacenote.instance.initialized()) {
            print("SDK is not initialized")
            return
        }
        
        if (mappingStarted || localizationStarted) {
            LibPlacenote.instance.setFrame(image: image, pose: pose)
        }
    }
    
    
    //Informs the delegate of changes to the quality of ARKit's device position tracking.
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var status = "Loading.."
        switch camera.trackingState {
        case ARCamera.TrackingState.notAvailable:
            status = "Not available"
        case ARCamera.TrackingState.limited(.excessiveMotion):
            status = "Excessive Motion."
        case ARCamera.TrackingState.limited(.insufficientFeatures):
            status = "Insufficient features"
        case ARCamera.TrackingState.limited(.initializing):
            status = "Initializing"
        case ARCamera.TrackingState.limited(.relocalizing):
            status = "Relocalizing"
        case ARCamera.TrackingState.normal:
            if (!trackingStarted) {
                trackingStarted = true
                print("ARKit Enabled, Start Mapping")
            }
            status = "Ready"
        }
        userLabel.text = status
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for (anchor) in anchors {
            planesVizAnchors.append(anchor)
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        node.transform = LibPlacenote.instance.processPose(pose: node.transform); //transform through
        planesVizNodes[anchor.identifier] = node; //keep track of plane nodes so you can move them once you localize to a new map.
        
        /*
         `SCNPlane` is vertically oriented in its local coordinate space, so
         rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
         */
        planeNode.eulerAngles.x = -.pi / 2
        
        // Make the plane visualization semitransparent to clearly show real-world placement.
        planeNode.opacity = 0.25
        
        /*
         Add the plane visualization to the ARKit-managed node so that it tracks
         changes in the plane anchor as plane estimation continues.
         */
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        /*
         Plane estimation may extend the size of the plane, or combine previously detected
         planes into a larger one. In the latter case, `ARSCNView` automatically deletes the
         corresponding node for one plane, then calls this method to update the size of
         the remaining plane.
         */
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
        
        node.transform = LibPlacenote.instance.processPose(pose: node.transform)
    }
}
