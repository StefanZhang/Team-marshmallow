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
import CoreLocation

class UserLocalizationViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, PNDelegate {
    

    private var graph  = AdjacencyList<String>()
    
    var localizedPlace = "" // This is place found by localization
    // Store the destination selected by WT
    var destination : [String] = []
    var camLoc = SCNVector3()
    var foundBreadCrumb = SCNVector3()
    
    @IBOutlet var navView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    //AR Scene
    private var navScene: SCNScene!
    
    // Placenote Tracking variables
    private var mappingStarted: Bool = false;
    private var localizationStarted: Bool = false;
    private var newMapfound = false
    
    //Variables to manage PlacenoteSDK features and helpers
    private var maps: [(String, LibPlacenote.MapMetadata)] = [("Sample Map", LibPlacenote.MapMetadata())]
    private var camManager: CameraManager? = nil;
    private var ptViz: FeaturePointVisualizer? = nil;
    private var planesVizAnchors = [ARAnchor]();
    private var planesVizNodes = [UUID: SCNNode]();
    
    // App related variables
    private var shapeManager: ShapeManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        
        //App Related initializations
        shapeManager = ShapeManager(scene: navScene, view: navView)
        // MAy need Gesture recognizer here
        
        
        //IMPORTANT: need to run this line to subscribe to pose and status events
        //Declare yourself to be one of the delegates of PNDelegate to receive pose and status updates
        LibPlacenote.instance.multiDelegate += self;
        
        LibPlacenote.instance.fetchMapList(listCb: onMapList)
        
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
        navView.showsStatistics = false
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
    
    
    @IBAction func startPressed(_ sender: Any) {
        let bestMap = findMap()
        mapLoading(map: bestMap.0, index: bestMap.1)
        self.newMapfound = true
    }
    
    @IBAction func loadedPressed(_ sender: Any) {
        
    }
    
    
    // MARK: - PNDelegate functions
    
    //Receive a pose update when a new pose is calculated
    func onPose(_ outputPose: matrix_float4x4, _ arkitPose: matrix_float4x4) -> Void {
        
    }
    
    
    func onStatusChange(_ prevStatus: LibPlacenote.MappingStatus, _ currStatus: LibPlacenote.MappingStatus) {
        if prevStatus != LibPlacenote.MappingStatus.running && currStatus == LibPlacenote.MappingStatus.running { //just localized draw shapes you've retrieved
            print ("Just localized, drawing view")
            shapeManager.drawView(parent: navScene.rootNode) //just localized redraw the shapes
            if mappingStarted {
                
                self.newMapfound = false
                statusLabel.text = "Move Slowly And Stay Within 3 Feet Of Features"
            }
            else if localizationStarted {
                statusLabel.text = "Map Found!"
            }
            //tapRecognizer?.isEnabled = true
            
            //As you are localized, the camera has been moved to match that of Placenote's Map. Transform the planes
            //currently being drawn from the arkit frame of reference to the Placenote map's frame of reference.
            for (_, node) in planesVizNodes {
                node.transform = LibPlacenote.instance.processPose(pose: node.transform);
            }
        }
        
        if prevStatus == LibPlacenote.MappingStatus.running && currStatus != LibPlacenote.MappingStatus.running { //just lost localization
            print ("Just lost")
            if mappingStarted {
                statusLabel.text = "Moved too fast. Map Lost"
            }
            //This was taken from OG ViewController
            //tapRecognizer?.isEnabled = false

            
        }
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

    // MARK: - ARSCNViewDelegate
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
    
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//        
//        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
//        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
//        let planeNode = SCNNode(geometry: plane)
//        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
//        
//        node.transform = LibPlacenote.instance.processPose(pose: node.transform); //transform through
//        planesVizNodes[anchor.identifier] = node; //keep track of plane nodes so you can move them once you localize to a new map.
//        
//        /*
//         `SCNPlane` is vertically oriented in its local coordinate space, so
//         rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
//         */
//        planeNode.eulerAngles.x = -.pi / 2
//        
//        // Make the plane visualization semitransparent to clearly show real-world placement.
//        planeNode.opacity = 0.25
//        
//        /*
//         Add the plane visualization to the ARKit-managed node so that it tracks
//         changes in the plane anchor as plane estimation continues.
//         */
//        node.addChildNode(planeNode)
//    }
    
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
    
    // MARK: - ARSessionDelegate
    
    //Provides a newly captured camera image and accompanying AR information to the delegate.
    func session(_ session: ARSession, didUpdate: ARFrame) {
        let image: CVPixelBuffer = didUpdate.capturedImage
        let pose: matrix_float4x4 = didUpdate.camera.transform

        camLoc = SCNVector3(pose.columns.3.x,pose.columns.3.y-0.8,pose.columns.3.z)


        // There was navigation/breadcrumb dropping here in OG viewController



        if (!LibPlacenote.instance.initialized()) {
            statusLabel.text = "SDK not initialized"
            return
        }

        if (mappingStarted || localizationStarted) {
            LibPlacenote.instance.setFrame(image: image, pose: pose)
        }
    }


    func nodeDistance (first: SCNVector3, second: SCNVector3) -> Float {
        let x = first.x - second.x
        let y = first.y - second.y
        let z = first.z - second.z
        return sqrt(x*x + y*y + z*z)
    }
    
    
    //Receive list of maps after it is retrieved. This is only fired when fetchMapList is called (see updateMapTable())
    func onMapList(success: Bool, mapList: [String: LibPlacenote.MapMetadata]) -> Void {
        maps.removeAll()
        if (!success) {
            print ("failed to fetch map list")
            statusLabel.text = "Map List not retrieved"
            return
        }
        
        //Cycle through the maplist and create a database of all the maps (place.key) and its metadata (place.value)
        for place in mapList {
            maps.append((place.key, place.value))
        }
        
        statusLabel.text = "Map List"

    }
    
    
    
    
    // Loads a map using the map name and the index in the list on maps
    func mapLoading(map: (String, LibPlacenote.MapMetadata), index: Int) -> Void
    {

        LibPlacenote.instance.loadMap(mapId: maps[index].0,
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
                                            let userdata = self.maps[index].1.userdata as? [String:Any]
                                            // This is placenote originally
                                            //                                      if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                            //                                        self.statusLabel.text = "Map Loaded. Look Around"
                                            //                                      }

                                            if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                                self.statusLabel.text = "Map Loaded. Look Around"
                                                
                                                self.localizedPlace = self.maps[index].0
                        
                                                self.foundBreadCrumb = self.getClosestBC(camlocVec: self.camLoc)
                                            
                                                // Adding a button for this functionality for now
                                                //self.performSegue(withIdentifier: "localizedToNav", sender:self)
                                              
                                                
                                            }
                                            else {
                                                self.statusLabel.text = "Map Loaded. Shape file not found"
                                            }
                                            LibPlacenote.instance.startSession(extend: true)


//                                            if (self.reportDebug) {
//                                                LibPlacenote.instance.startReportRecord (uploadProgressCb: ({(completed: Bool, faulted: Bool, percentage: Float) -> Void in
//                                                    if (completed) {
//                                                        self.statusLabel.text = "Dataset Upload Complete"
//                                                        self.fileTransferLabel.text = ""
//                                                    } else if (faulted) {
//                                                        self.statusLabel.text = "Dataset Upload Faulted"
//                                                        self.fileTransferLabel.text = ""
//                                                    } else {
//                                                        self.fileTransferLabel.text = "Dataset Upload: " + String(format: "%.3f", percentage) + "/1.0"
//                                                    }
//                                                })
//                                                )
//                                                print ("Started Debug Report")
//                                            }

                                            //self.tapRecognizer?.isEnabled = true
                                        } else if (faulted) {
                                            print ("Couldnt load map: " + self.maps[index].0)
                                            self.statusLabel.text = "Load error Map Id: " +  self.maps[index].0
                                        } else {
                                            print ("Progress: " + percentage.description)
                                        }
        }
        )

    }
    // Looks at all the maps and finds the one that is most likely the one the user is trying to load
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
        var nextMap = maps[0]
        var counter = 0
        var index = 0
        for map in maps
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
    
    func getClosestBC (camlocVec: SCNVector3) -> SCNVector3 {
        let shapePositions = shapeManager.getShapePositions()
        
        for vector3 in shapePositions {
            if ( nodeDistance(first: vector3, second: camlocVec) < 1.0 ){
                return vector3
            }
        }
        return SCNVector3()
    }
    
    func SCNV3toString(vec: SCNVector3) -> String{
        let x = NSString(format: "%.8f", vec.x)
        let y = NSString(format: "%.8f", vec.y)
        let z = NSString(format: "%.8f", vec.z)
        let s3 = NSString(format:"%@,%@,%@",x,y,z)
        let resultString = s3 as String
        return resultString
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "localizedToNav"){
            let viewControllerUM = segue.destination as? ViewControllerUM
            let mapName = localizedPlace
            let initialBC = SCNV3toString(vec: foundBreadCrumb)
            let result = [mapName, initialBC]
            dump(result)
            dump(self.destination)
            
            viewControllerUM?.destination = self.destination
            viewControllerUM?.initialLocation = result
        }
    }
//
//    // Finds out if the user is at a checkpoint or not (must be at least 1 object placed in the map to work)
//    func getClosetNode(camera_pos: SCNVector3, map: AdjacencyList<String>) -> Bool{
//
//        if shapeManager.getShapePositions().count > 0 {
//            for position in shapeManager.getShapePositions()
//            {
//                let pos = SCNV3toString(vec: position)
//
//                let node = Hash_Node_Dict[pos]
//                let tre = node?.geometry?.description
//
//                if(tre != nil)
//                {
//                    let T = Array(tre!)[4]
//                    if( T == "B")
//                    {
//
//                        if (nodeDistance(first: camera_pos, second: node?.position ?? SCNVector3(0.00, 0.00, 0.00)) < 1.5)
//                        {
//                            let alert = UIAlertController(title: "Alert", message: "At checkpoint", preferredStyle: .alert)
//                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
//                                switch action.style{
//                                case .default:
//                                    print("default")
//
//                                case .cancel:
//                                    print("cancel")
//
//                                case .destructive:
//                                    print("destructive")
//
//
//                                }}))
//                            self.present(alert, animated: true, completion: nil)
//
//                            return true
//                        }
//                    }
//                    else if(T == "P")
//                    {
//                        if (nodeDistance(first: camera_pos, second: node?.position ?? SCNVector3(0.00, 0.00, 0.00)) < 1.5)
//                        {
//                            let alert = UIAlertController(title: "Alert", message: "You have arrived", preferredStyle: .alert)
//                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
//                                switch action.style{
//                                case .default:
//                                    print("default")
//
//                                case .cancel:
//                                    print("cancel")
//
//                                case .destructive:
//                                    print("destructive")
//
//
//                                }}))
//                            self.present(alert, animated: true, completion: nil)
//
//                            return true
//                        }
//                    }
//                }
//
//
//
//            }
//        }
//        return false
//    }
//
//    //Informs the delegate of changes to the quality of ARKit's device position tracking.
//    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
//        var status = "Loading.."
//        switch camera.trackingState {
//        case ARCamera.TrackingState.notAvailable:
//            status = "Not available"
//        case ARCamera.TrackingState.limited(.excessiveMotion):
//            status = "Excessive Motion."
//        case ARCamera.TrackingState.limited(.insufficientFeatures):
//            status = "Insufficient features"
//        case ARCamera.TrackingState.limited(.initializing):
//            status = "Initializing"
//        case ARCamera.TrackingState.limited(.relocalizing):
//            status = "Relocalizing"
//        case ARCamera.TrackingState.normal:
//            if (!trackingStarted) {
//                trackingStarted = true
//                print("ARKit Enabled, Start Mapping")
//                newMapButton.isEnabled = true
//                newMapButton.setTitle("New Map", for: .normal)
//            }
//            status = "Ready"
//        }
//        statusLabel.text = status
//
//    }
//
//    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
//        for (anchor) in anchors {
//            planesVizAnchors.append(anchor)
//        }
//    }
//
//    // MARK: - CLLocationManagerDelegate
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        lastLocation = locations.last
//    }

}
