//
//  ViewController.swift
//  Shape Dropper (Placenote SDK iOS Sample)
//
//  Created by Prasenjit Mukherjee on 2017-09-01.
//  Copyright © 2017 Vertical AI. All rights reserved.
//
// Test for github

import UIKit
import CoreLocation
import SceneKit
import ARKit
import PlacenoteSDK



//changed
var last_loc = SCNVector3(0,0,0)

//Dictionary for hash and node pairs
var Hash_Node_Dict = [String:SCNNode]()

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UITableViewDelegate, UITableViewDataSource, PNDelegate, CLLocationManagerDelegate {
  
  
  //UI Elements
  @IBOutlet var scnView: ARSCNView!
  
  //UI Elements for the map table
  @IBOutlet var mapTable: UITableView!
  @IBOutlet var filterLabel2: UILabel!
  @IBOutlet var filterLabel1: UILabel!
  @IBOutlet var filterSlider: UISlider!
  
  
  @IBOutlet var newMapButton: UIButton!
  @IBOutlet var pickMapButton: UIButton!
  @IBOutlet var statusLabel: UILabel!
  @IBOutlet var showPNLabel: UILabel!
  @IBOutlet var showPNSelection: UISwitch!
  @IBOutlet var planeDetLabel: UILabel!
  @IBOutlet var planeDetSelection: UISwitch!
  @IBOutlet var fileTransferLabel: UILabel!
  
  
  //AR Scene
  private var scnScene: SCNScene!
  
  //Status variables to track the state of the app with respect to libPlacenote
  private var trackingStarted: Bool = false;
  private var mappingStarted: Bool = false;
  private var localizationStarted: Bool = false;
  private var reportDebug: Bool = false
  private var maxRadiusSearch: Float = 500.0 //m
  private var currRadiusSearch: Float = 0.0 //m
  
  
  
  //Application related variables
  private var shapeManager: ShapeManager!
  private var tapRecognizer: UITapGestureRecognizer? = nil //initialized after view is loaded
  
  
  //Variables to manage PlacenoteSDK features and helpers
  private var maps: [(String, LibPlacenote.MapMetadata)] = [("Sample Map", LibPlacenote.MapMetadata())]
  private var camManager: CameraManager? = nil;
  private var ptViz: FeaturePointVisualizer? = nil;
  private var planesVizAnchors = [ARAnchor]();
  private var planesVizNodes = [UUID: SCNNode]();
  
  private var graph  = AdjacencyList<String>()
  
  
  private var showFeatures: Bool = true
  private var planeDetection: Bool = false
  
  private var locationManager: CLLocationManager!
  private var lastLocation: CLLocation? = nil
  // Testing graph

  //Setup view once loaded
  override func viewDidLoad() {

    
    
    super.viewDidLoad()
    setupView()
    setupScene()
    //App Related initializations
    shapeManager = ShapeManager(scene: scnScene, view: scnView)
    tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    tapRecognizer!.numberOfTapsRequired = 1
    tapRecognizer!.isEnabled = false
    scnView.addGestureRecognizer(tapRecognizer!)
    
    //IMPORTANT: need to run this line to subscribe to pose and status events
    //Declare yourself to be one of the delegates of PNDelegate to receive pose and status updates
    LibPlacenote.instance.multiDelegate += self;
    
    //Initialize tableview for the list of maps
    mapTable.delegate = self
    mapTable.dataSource = self
    mapTable.allowsSelection = true
    mapTable.isUserInteractionEnabled = true
    mapTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    
    //UI Updates
    newMapButton.isEnabled = false
    toggleMappingUI(true) //hide mapping UI options
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
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    scnView.session.pause()
  }
  
  //Function to setup the view and setup the AR Scene including options
  func setupView() {
    scnView = self.view as! ARSCNView
    scnView.showsStatistics = true
    scnView.autoenablesDefaultLighting = true
    scnView.delegate = self
    scnView.session.delegate = self
    scnView.isPlaying = true
    scnView.debugOptions = []
    mapTable.isHidden = true //hide the map list until 'Load Map' is clicked
    filterSlider.isContinuous = false
    toggleSliderUI(true, reset: true) //hide the radius search UI, reset values as we are initializating
    //scnView.debugOptions = ARSCNDebugOptions.showFeaturePoints
    //scnView.debugOptions = ARSCNDebugOptions.showWorldOrigin
  }
  
  //Function to setup AR Scene
  func setupScene() {
    scnScene = SCNScene()
    scnView.scene = scnScene
    ptViz = FeaturePointVisualizer(inputScene: scnScene);
    ptViz?.enableFeaturePoints()
    
    if let camera: SCNNode = scnView?.pointOfView {
      camManager = CameraManager(scene: scnScene, cam: camera)
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scnView.frame = view.bounds
  }
  
  
  // MARK: - PNDelegate functions
  
  //Receive a pose update when a new pose is calculated
  func onPose(_ outputPose: matrix_float4x4, _ arkitPose: matrix_float4x4) -> Void {
    
  }
  
  
  
  //Receive a status update when the status changes
  func onStatusChange(_ prevStatus: LibPlacenote.MappingStatus, _ currStatus: LibPlacenote.MappingStatus) {
    if prevStatus != LibPlacenote.MappingStatus.running && currStatus == LibPlacenote.MappingStatus.running { //just localized draw shapes you've retrieved
      print ("Just localized, drawing view")
      shapeManager.drawView(parent: scnScene.rootNode) //just localized redraw the shapes
      if mappingStarted {
        statusLabel.text = "Tap anywhere to add Shapes, Move Slowly"
      }
      else if localizationStarted {
        statusLabel.text = "Map Found!"
      }
      tapRecognizer?.isEnabled = true
      
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
      //changed
      tapRecognizer?.isEnabled = false
      //tapRecognizer?.isEnabled = true
      
    }
    
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
    self.mapTable.reloadData() //reads from maps array (see: tableView functions)              //Need to look through all the maps for the destination
    self.mapTable.isHidden = false
    self.toggleSliderUI(false, reset: false)
    self.tapRecognizer?.isEnabled = false
  }
  
  // MARK: - UI functions
  
  @IBAction func newSaveMapButton(_ sender: Any) {
    
    if (trackingStarted && !mappingStarted) { //ARKit is enabled, start mapping
      mappingStarted = true
      
      LibPlacenote.instance.stopSession()
      
      LibPlacenote.instance.startSession()
      
      if (reportDebug) {
        LibPlacenote.instance.startReportRecord(uploadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
          if (completed) {
            self.statusLabel.text = "Dataset Upload Complete"
            self.fileTransferLabel.text = ""
          } else if (faulted) {
            self.statusLabel.text = "Dataset Upload Faulted"
            self.fileTransferLabel.text = ""
          } else {
            self.fileTransferLabel.text = "Dataset Upload: " + String(format: "%.3f", percentage) + "/1.0"
          }
        })
        print ("Started Debug Report")
      }
      
      localizationStarted = false
      pickMapButton.setTitle("Load Map", for: .normal)
      newMapButton.setTitle("Save Map", for: .normal)
      statusLabel.text = "Mapping: Tap to add shapes!"
      tapRecognizer?.isEnabled = true
      mapTable.isHidden = true
      toggleSliderUI(true, reset: false)
      toggleMappingUI(false)
      shapeManager.clearShapes() //creating new map, remove old shapes.
    }
    else if (mappingStarted) { //mapping been running, save map
      print("Saving Map")
      statusLabel.text = "Saving Map"
      mappingStarted = false
      LibPlacenote.instance.saveMap(
        savedCb: {(mapId: String?) -> Void in
          if (mapId != nil) {
            self.statusLabel.text = "Saved Id: " + mapId! //update UI
            LibPlacenote.instance.stopSession()
            
            let metadata = LibPlacenote.MapMetadataSettable()
            metadata.name = RandomName.Get()
            self.statusLabel.text = "Saved Map: " + metadata.name! //update UI
            
            if (self.lastLocation != nil) {
              metadata.location = LibPlacenote.MapLocation()
              metadata.location!.latitude = self.lastLocation!.coordinate.latitude
              metadata.location!.longitude = self.lastLocation!.coordinate.longitude
              metadata.location!.altitude = self.lastLocation!.altitude
            }
            var userdata: [String:Any] = [:]
            userdata["shapeArray"] = self.shapeManager.getShapeArray()
            metadata.userdata = userdata
            
            
            if (!LibPlacenote.instance.setMapMetadata(mapId: mapId!, metadata: metadata, metadataSavedCb: {(success: Bool) -> Void in})) {
              print ("Failed to set map metadata")
            }
            self.planeDetSelection.isOn = false
            self.planeDetection = false
            self.configureSession()
          } else {
            NSLog("Failed to save map")
          }
      },
        uploadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
          if (completed) {
            print ("Uploaded!")
            self.fileTransferLabel.text = ""
          } else if (faulted) {
            print ("Couldnt upload map")
          } else {
            print ("Progress: " + percentage.description)
            self.fileTransferLabel.text = "Map Upload: " + String(format: "%.3f", percentage) + "/1.0"
          }
      }
      )
      newMapButton.setTitle("New Map", for: .normal)
      pickMapButton.setTitle("Load Map", for: .normal)
      tapRecognizer?.isEnabled = false
      localizationStarted = false
      toggleMappingUI(true) //hide mapping UI
    }
     updateGraph()
    
    
  }
  
  @IBAction func pickMap(_ sender: Any) {
    
    if (localizationStarted) { // currently a map is loaded. StopSession and clearView

      shapeManager.clearShapes()
      ptViz?.reset()
      LibPlacenote.instance.stopSession()
      localizationStarted = false
      mappingStarted = false
      pickMapButton.setTitle("Load Map", for: .normal)
      newMapButton.setTitle("New Map", for: .normal)
      statusLabel.text = "Cleared"
      toggleMappingUI(true) //hided mapping options
      planeDetSelection.isOn = false
      planeDetection = false
      dump(self.shapeManager.getShapePositions())
      configureSession()
      //dump(self.shapeManager.getShapePositions())
      return
    }
    
    if (mapTable.isHidden) { //fetch map list and show table of maps
      updateMapTable()
      pickMapButton.setTitle("Cancel", for: .normal)
      newMapButton.isEnabled = false
      statusLabel.text = "Fetching Map List"
      toggleSliderUI(true, reset: true)
    }
    else { //map load/localization session cancelled
      mapTable.isHidden = true
      toggleSliderUI(true, reset: false)
      pickMapButton.setTitle("Load Map", for: .normal)
      newMapButton.isEnabled = true
      statusLabel.text = "Map Load cancelled"
    }
  }
  
  @IBAction func onShowFeatureChange(_ sender: Any) {
    showFeatures = !showFeatures
    if (showFeatures) {
      ptViz?.enableFeaturePoints()
    }
    else {
      ptViz?.disableFeaturePoints()
    }
  }
  
  @IBAction func onDistanceFilterChange(_ sender: UISlider) {
    let currentValue = Float(sender.value)*maxRadiusSearch
    filterLabel1.text = String.localizedStringWithFormat("Distance filter: %.2f km", currentValue/1000.0)
    currRadiusSearch = currentValue
    updateMapTable(radius: currRadiusSearch)
  }
  
  @IBAction func onPlaneDetectionOnOff(_ sender: Any) {
    planeDetection = !planeDetection
    configureSession()
  }
  
  func configureSession() {
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    configuration.worldAlignment = ARWorldTrackingConfiguration.WorldAlignment.gravity //TODO: Maybe not heading?
    
    if (planeDetection) {
      if #available(iOS 11.3, *) {
        configuration.planeDetection = [.horizontal, .vertical]
      } else {
        configuration.planeDetection = [.horizontal]
      }
    }
    else {
      for (_, node) in planesVizNodes {
        node.removeFromParentNode()
      }
      for (anchor) in planesVizAnchors { //remove anchors because in iOS versions <11.3, the anchors are not automatically removed when plane detection is turned off.
        scnView.session.remove(anchor: anchor)
      }
      planesVizNodes.removeAll()
      configuration.planeDetection = []
    }
    // Run the view's session
    scnView.session.run(configuration)
  }
  
  func toggleSliderUI (_ on: Bool, reset: Bool) {
    filterSlider.isHidden = on
    filterLabel1.isHidden = on
    filterLabel2.isHidden = on
    if (reset) {
      filterSlider.value = 1.0
      filterLabel1.text = "Distance slider: Off"
    }
  }
  
  func toggleMappingUI(_ on: Bool) {
    planeDetLabel.isHidden = on
    planeDetSelection.isHidden = on
    showPNLabel.isHidden = on
    showPNSelection.isHidden = on
  }
  
  // MARK: - UITableViewDelegate and UITableviewDataSource to manage retrieving, viewing, deleting and selecting maps on a TableView
  
  //Return count of maps
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    print(String(format: "Map size: %d", maps.count))
    return maps.count
  }
  
  //Label Map rows
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let map = self.maps[indexPath.row]
    var cell:UITableViewCell? = mapTable.dequeueReusableCell(withIdentifier: map.0)
    if cell==nil {
      cell =  UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: map.0)
    }
    cell?.textLabel?.text = map.0
    
    let name = map.1.name
    if name != nil && !name!.isEmpty {
      cell?.textLabel?.text = name
    }
    
    var subtitle = "Distance Unknown"
    
    let location = map.1.location
    
    if (lastLocation == nil) {
      subtitle = "User location unknown"
    } else if (location == nil) {
      subtitle = "Map location unknown"
    } else {
      let distance = lastLocation!.distance(from: CLLocation(
        latitude: location!.latitude,
        longitude: location!.longitude))
      subtitle = String(format: "Distance: %0.3fkm", distance / 1000)
    }
    
    cell?.detailTextLabel?.text = subtitle
    
    return cell!
  }
  
  //Map selected
  
  //Must find out what new graph needs to be selected
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    print(String(format: "Retrieving row: %d", indexPath.row))
    print("Retrieving mapId: " + maps[indexPath.row].0)
    statusLabel.text = "Retrieving mapId: " + maps[indexPath.row].0
    let alert = UIAlertController(title: "Alert", message: "Finding all needed maps", preferredStyle: .alert)
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
    LibPlacenote.instance.loadMap(mapId: maps[indexPath.row].0,
                                  downloadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                                    if (completed) {
                                      self.mappingStarted = true //extending the map
                                      self.localizationStarted = true
                                      self.mapTable.isHidden = true
                                      self.pickMapButton.setTitle("Stop/Clear", for: .normal)
                                      self.newMapButton.isEnabled = true
                                      self.newMapButton.setTitle("Save Map", for: .normal)
                                      
                                      self.toggleMappingUI(false) //show mapping options UI
                                      self.toggleSliderUI(true, reset: true) //hide + reset UI for later
                                      
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
                                      let userdata = self.maps[indexPath.row].1.userdata as? [String:Any]
                                      if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                        self.statusLabel.text = "Map Loaded. Look Around"
                                      } else {
                                        self.statusLabel.text = "Map Loaded. Shape file not found"
                                      }
                                      LibPlacenote.instance.startSession(extend: true)
                                      
                                      
                                      if (self.reportDebug) {
                                        LibPlacenote.instance.startReportRecord (uploadProgressCb: ({(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                                          if (completed) {
                                            self.statusLabel.text = "Dataset Upload Complete"
                                            self.fileTransferLabel.text = ""
                                          } else if (faulted) {
                                            self.statusLabel.text = "Dataset Upload Faulted"
                                            self.fileTransferLabel.text = ""
                                          } else {
                                            self.fileTransferLabel.text = "Dataset Upload: " + String(format: "%.3f", percentage) + "/1.0"
                                          }
                                        })
                                        )
                                        print ("Started Debug Report")
                                      }
                                      
                                      self.tapRecognizer?.isEnabled = true
                                    } else if (faulted) {
                                      print ("Couldnt load map: " + self.maps[indexPath.row].0)
                                      self.statusLabel.text = "Load error Map Id: " +  self.maps[indexPath.row].0
                                    } else {
                                      print ("Progress: " + percentage.description)
                                    }
    }
    )
  }
  
  //Make rows editable for deletion
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  //Delete Row and its corresponding map
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if (editingStyle == UITableViewCellEditingStyle.delete) {
      statusLabel.text = "Deleting Map:" + maps[indexPath.row].0
      LibPlacenote.instance.deleteMap(mapId: maps[indexPath.row].0, deletedCb: {(deleted: Bool) -> Void in
        if (deleted) {
          print("Deleting: " + self.maps[indexPath.row].0)
          self.statusLabel.text = "Deleted Map: " + self.maps[indexPath.row].0
          self.maps.remove(at: indexPath.row)
          self.mapTable.reloadData()
        }
        else {
          print ("Can't Delete: " + self.maps[indexPath.row].0)
          self.statusLabel.text = "Can't Delete: " + self.maps[indexPath.row].0
        }
      })
    }
  }
  
  func updateMapTable() {
    LibPlacenote.instance.fetchMapList(listCb: onMapList)
  }
  
  func updateMapTable(radius: Float) {
    LibPlacenote.instance.searchMaps(latitude: self.lastLocation!.coordinate.latitude, longitude: self.lastLocation!.coordinate.longitude, radius: Double(radius), listCb: onMapList)
  }
  
  @objc func handleTap(sender: UITapGestureRecognizer) {
    
    let tapLocation = sender.location(in: scnView)
    let hitTestResults = scnView.hitTest(tapLocation, types: .featurePoint)
    if let result = hitTestResults.first {
      let pose = LibPlacenote.instance.processPose(pose: result.worldTransform)
      //shapeManager.spawnRandomShape(position: pose.position())
      
      
      
// Generate Sphere according to camera's location
//      let frame = scnView.session.currentFrame
//      let camera = frame?.camera
//      let loc = camera?.transform
//      let loc01 = loc?.columns.3
//      let x = loc01?.x
//      var y = loc01?.y
//      //let y2 = y? - 0.5 ?? 0.0
//      let z = loc01?.z
//      let loc02 = SCNVector3(x ?? 0,y ?? 0,z ?? 0)
//      let loc03 = SCNVector3(x: 0,y: 1.5,z: 0)
//      dump(loc02)
//
//      let ball = SCNSphere(radius: 0.02)
//      var node = SCNNode(geometry: ball)
//      node.position = SCNVector3(0,-0.5,0)
//      scnView.pointOfView?.addChildNode(node)
//      dump(scnView.pointOfView?.position)
//
//      let loc = pose.columns.3
//      let loc01 = SCNVector3(loc.x,loc.y,loc.z)
//      dump(loc01 )
//
//
//      shapeManager.spawnNewBreadCrumb(position1: loc02, position2: loc03)
//
//      scnView.scene.rootNode.addChildNode(generateBreadCrumb(loc02: loc02, loc03: loc03))
//      dump(pose.position())
      
      //dump( self.shapeManager.getShapePositions() ) //Matt commented this out
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
  
  // MARK: - ARSessionDelegate
  
  //Provides a newly captured camera image and accompanying AR information to the delegate.
  func session(_ session: ARSession, didUpdate: ARFrame) {
    let image: CVPixelBuffer = didUpdate.capturedImage
    let pose: matrix_float4x4 = didUpdate.camera.transform
    
    //changed
    let cam_loc = pose.columns.3
    let loc01 = SCNVector3(cam_loc.x,cam_loc.y-0.8,cam_loc.z)
    
    if (nodeDistance(first: loc01, second: last_loc) > 1.5){
      //dump(loc01) Matt commented this out
      if(!self.shapeManager.checkAdjacent(selfPos: loc01)){
        shapeManager.spawnNewBreadCrumb(position1: loc01)
        last_loc = loc01
      }
    }
    //shapeManager.spawnNewBreadCrumb(position1: SCNVector3(x: 1.125, y: 2.256, z: 3.64))

    //shapeManager.spawnRandomShape(position: subtraction(left:loc02,right:loc03))
    
    
    
    
    if (!LibPlacenote.instance.initialized()) {
      print("SDK is not initialized")
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
        newMapButton.isEnabled = true
        newMapButton.setTitle("New Map", for: .normal)
      }
      status = "Ready"
    }
    statusLabel.text = status
  }
  
  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    for (anchor) in anchors {
      planesVizAnchors.append(anchor)
    }
  }
  
  // MARK: - CLLocationManagerDelegate
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    lastLocation = locations.last
  }

    @IBAction func dropCheckpoint(_ sender: Any) {
        let frame = scnView.session.currentFrame
        let camera = frame?.camera
        let loc = camera?.transform
        let loc01 = loc?.columns.3
        let x = loc01?.x
        let y = loc01?.y
        //let y2 = y? - 0.5 ?? 0.0
        let z = loc01?.z
        let loc02 = SCNVector3(x ?? 0,y ?? 0,z ?? 0)
        shapeManager.spawnNewCheckpoint(position_01: loc02)
      updateGraph()
      
      // Testing
      let dest = graph.adjacencyDict.keys.randomElement()
      if dest != graph.adjacencyDict.keys.first {
        let out = graph.aStar(start: graph.adjacencyDict.keys.first!, destination: dest!)
        dump(out)
        var outArray = ""
        
        for vertex in out{
          outArray = outArray+":"+vertex.description
          print(outArray)
        }
        outArray.append("Start" + (graph.adjacencyDict.keys.first?.description)!)
        outArray.append("End" + ((dest?.description)!))

        let alert = UIAlertController(title: "Out", message: outArray, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
          NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
        //
      }
      
      if 1<2 {
        print("Graph TEEEEEESTING--------------")
        var toygraph  = AdjacencyList<String>()
        let n1 = NavigationNode(number: 1.0, Stype: ShapeType.Sphere, position: SCNVector3(x: 1, y: 0, z: 0))
        let n2 = NavigationNode(number: 1.0, Stype: ShapeType.Sphere, position: SCNVector3(x: 1, y: 0, z: 0))
        let n3 = NavigationNode(number: 1.0, Stype: ShapeType.Sphere, position: SCNVector3(x: 1, y: 1, z: 0))
        let n4 = NavigationNode(number: 1.0, Stype: ShapeType.Sphere, position: SCNVector3(x: 2, y: 2, z: 0))
        
        let v1 = toygraph.createVertex(data: n1.toString())
        let v2 = toygraph.createVertex(data: n2.toString())
        let v3 = toygraph.createVertex(data: n3.toString())
        let v4 = toygraph.createVertex(data: n4.toString())
        
        let c1 = SCNVector3(x: 1, y: 0, z: 0)
        let c2 = SCNVector3(x: 1, y: 0, z: 0)
        let c3 = SCNVector3(x: 1, y: 1, z: 0)
        let c4 = SCNVector3(x: 2, y: 2, z: 0)
        
        toygraph.add(.undirected, from: v1, to: v2, weight: Double(nodeDistance(first: c1, second: c2)))
        toygraph.add(.undirected, from: v2, to: v3, weight: Double(nodeDistance(first: c2, second: c4)))
        toygraph.add(.undirected, from: v1, to: v3, weight: Double(nodeDistance(first: c1, second: c3)))
        toygraph.add(.undirected, from: v3, to: v4, weight: Double(nodeDistance(first: c3, second: c4)))

        let out = toygraph.aStar(start: v1, destination: v4)
        //let out = self.graph.aStar(start: graph.adjacencyDict.keys.first ?? Vertex<String>(data:"0"), destination: graph.adjacencyDict.keys.randomElement() ?? Vertex<String>(data:"0"))
        print("This is the output of aStar. should be v1 v3 v4")
        dump(out)
        var outArray = ""
        
        for vertex in out{
          outArray = outArray+":"+vertex.description
          print(outArray)
        }
        
        let alert = UIAlertController(title: "Out", message: outArray, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
          NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
        //
      }
      
    }
    
    @IBAction func dropDestination(_ sender: Any) {
        let frame = scnView.session.currentFrame
        let camera = frame?.camera
        let loc = camera?.transform
        let loc01 = loc?.columns.3
        let x = loc01?.x
        let y = loc01?.y
        //let y2 = y? - 0.5 ?? 0.0
        let z = loc01?.z
        let loc02 = SCNVector3(x ?? 0,y ?? 0,z ?? 0)
        shapeManager.spawnNewDestination(position_1: loc02)

      
        //dump(graph.description)
      
    }
  
  func SCNV3toString(vec: SCNVector3) -> String{
    let x = NSString(format: "%.8f", vec.x)
    let y = NSString(format: "%.8f", vec.y)
    let z = NSString(format: "%.8f", vec.z)
    let s3 = NSString(format:"%@,%@,%@",x,y,z)
    let resultString = s3 as String
    return resultString
  }
  
  func updateGraph(){
    // load the position from breadcrums
    let shapePositions = shapeManager.getShapePositions()
    let shapeNodes = shapeManager.getShapeNodes()

    var ctr = 0
    while ctr < shapePositions.count - 1{
      let vec1s = SCNV3toString(vec: shapePositions[ctr])
      let vec2s = SCNV3toString(vec: shapePositions[ctr+1])
      let d1 = graph.createVertex(data: vec1s)
      let d2 = graph.createVertex(data: vec2s)
      
      //insert the hash string as key and node as value
      Hash_Node_Dict[vec1s] = shapeNodes[ctr]
      Hash_Node_Dict[vec2s] = shapeNodes[ctr+1]
      
      // insert the nodes to undirected graph
      graph.add(.undirected, from: d1, to: d2, weight: 1.5)
      ctr+=1
    }
    
//    FOR DEBUG ONLY
    for (key, value) in Hash_Node_Dict {
      print("Key:\(key) -  Value:\(value)")
    }
    
//    FOR Debug ONLY
    print(graph.description)
  }
  
    @IBAction func showPath(_ sender: Any) {
      print("This is the graph when showPath get called")
      dump(graph)
    }
    
    
}



