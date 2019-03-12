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

// Array of V3 of nearest breadcrumbs
var nearestShapes = [SCNVector3]()

//changed
var last_loc = SCNVector3(0,0,0)

//Dictionary for hash and node pairs
var Hash_Node_Dict = [String:SCNNode]()

//Input map name from User
var mapname = ""

//Input destination name from user
var destination_name_meta = ""

var category_name_meta = ""

var destination_pos = ""

// default not to drop breadcrumbs
var canDropBC = false

//Dictionary that contains the destination as the key and position as the val
var Dest_Pos_Dict = [String:String]()
//Dictionary that contains the destination as the key and category as the val
var Dest_Cat_Dict = [String:String]()

//Dictionary that contains the checkpoint's vector3 as the key and their core location as the value
var Checkpoint_CL_Dict = [String:String]()

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
  
  let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
 
  
  //AR Scene
  private var scnScene: SCNScene!
  
  //Status variables to track the state of the app with respect to libPlacenote
  private var trackingStarted: Bool = false;
  private var mappingStarted: Bool = false;
  private var localizationStarted: Bool = false;
  private var reportDebug: Bool = false
  private var maxRadiusSearch: Float = 500.0 //m
  private var currRadiusSearch: Float = 0.0 //m
  private var newMapfound = false
  
  
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
  
  //changed

  
  override func viewDidAppear(_ animated: Bool) {
    //self.performSegue(withIdentifier: "loginView", sender: self)
  }
  
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
    scnView.session.delegate =  self
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
        self.newMapfound = false
        statusLabel.text = "Move Slowly And Stay Within 3 Feet Of Features"
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
      // enable BC dropping
      canDropBC = true
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
      
      //Pop up the save map window
      let MapName_alert = UIAlertController(title: "Enter Name of the map!", message: " ", preferredStyle: UIAlertControllerStyle.alert)
      
      MapName_alert.addTextField(configurationHandler: {(textField: UITextField!) in
        textField.placeholder = "Enter Map name:"
      })
      
      MapName_alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
        
        if let name = MapName_alert.textFields?.first?.text {
          // Set the text field to var mapname
          mapname = name
        }
      }))
      self.present(MapName_alert, animated: true, completion: nil)
      
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
            
            // assign the map name to metadata
            metadata.name = mapname
            
            self.statusLabel.text = "Saved Map: " + metadata.name! //update UI
            
            if (self.lastLocation != nil) {
              metadata.location = LibPlacenote.MapLocation()
              metadata.location!.latitude = self.lastLocation!.coordinate.latitude
              metadata.location!.longitude = self.lastLocation!.coordinate.longitude
              metadata.location!.altitude = self.lastLocation!.altitude
            }
            
            var userdata: [String:Any] = [:]
//            dump(self.shapeManager.getShapeArray())
            userdata["shapeArray"] = self.shapeManager.getShapeArray()
            
            if (Dest_Pos_Dict.isEmpty){
              print("No Destination Dropped for this map")
            }
            else{
              userdata["destinationDict"] = Dest_Pos_Dict
            }
            
            if (Dest_Cat_Dict.isEmpty){
              print("No Category Dropped for this Destination")
            }
            else{
              userdata["CategoryDict"] = Dest_Cat_Dict
            }
            
            // store checkpoint and their corresponding CoreLocation
            
//            if (Checkpoint_CL_Dict.isEmpty){
//              print("No Checkpoint Dropped for this map")
//            }
//            else{
//              userdata["CheckpointDict"] = Checkpoint_CL_Dict
//            }
            
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
      
      shapeManager.clearShapes()
      newMapButton.setTitle("New Map", for: .normal)
      pickMapButton.setTitle("Load Map", for: .normal)
      tapRecognizer?.isEnabled = false
      localizationStarted = false
      toggleMappingUI(true) //hide mapping UI
    }
     updateGraph()
    
    
  }
  
  @IBAction func pickMap(_ sender: Any) {
    canDropBC = false
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


    LibPlacenote.instance.loadMap(mapId: maps[indexPath.row].0,
                                  downloadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                                    if (completed) {
                                      self.mappingStarted = true //extending the map
                                      self.localizationStarted = true
                                      self.mapTable.isHidden = true
                                      self.pickMapButton.setTitle("Stop", for: .normal)
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
                                      // This is placenote originally
//                                      if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
//                                        self.statusLabel.text = "Map Loaded. Look Around"
//                                      }
                                      if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                        self.statusLabel.text = "Map Loaded. Look Around"
                                      }
                                      else {
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
    print("This is the map name:")
    print(maps[indexPath.row].0) // Need to call above function with next map at checkpoint
    print("Second thing in maps:")
    //print(maps[1].0)
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
    //let camPos = pose.columns.3
    // Camera Location in Vector3
    let camLoc = SCNVector3(pose.columns.3.x,pose.columns.3.y-0.8,pose.columns.3.z)
    let distance = Float(1.5)
    if (nodeDistance(first: camLoc, second: last_loc) > distance && canDropBC == true){
      let adjLocs = self.shapeManager.checkAdjacent(selfPos: camLoc, distance: distance) // Type vector3
      if(adjLocs.isEmpty){
        shapeManager.spawnNewBreadCrumb(position1: camLoc)
        last_loc = camLoc
      }
    }
    
    nearestShapes = shapeManager.checkAdjacent(selfPos: camLoc, distance: 0.3)
    if (!nearestShapes.isEmpty) {
      print("This is the closest BC")
      dump(nearestShapes)
    }
    // part one recognize that you are at a checkpoint
    if (self.newMapfound == false)
    {
      
      updateGraph()
      if (getClosetNode(camera_pos: camLoc, map: graph))
      {
        print("Closest map:")
        let bestMap = findMap()
        print(bestMap)
        mapLoading(map: bestMap.0, index: bestMap.1)
        self.newMapfound == true
        //shapeManager.drawView(parent: scnScene.rootNode) //just localized redraw the shapes
      }
    }
    
    //part two delete everything from map and load next one
    // shapeManager.clearShapes()
    
    
    
    // This is the camera position
    
    label.center = CGPoint(x: 160, y: 285)
    label.textAlignment = .center
//    let frame = scnView.session.currentFrame
//    let camera = frame?.camera
//    let loc = camera?.transform
//    let loc01 = loc?.columns.3
//
//    let x1 = loc01?.x ?? 0.000
//    let y1 = loc01?.y ?? 0.000
//    let z1 = loc01?.z ?? 0.000
//
//    let formattedx = String(format: "%.3f", x1)
//    let formattedy = String(format: "%.3f", y1)
//    let formattedz = String(format: "%.3f", z1)
    
//    label.text = //formattedx + "|" + formattedy + "|" + formattedz   //x + y + z
//    self.view.addSubview(label)    //shapeManager.spawnNewBreadCrumb(position1: SCNVector3(x: 1.125, y: 2.256, z: 3.64))

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
  
  func mapLoading(map: (String, LibPlacenote.MapMetadata), index: Int) -> Void
  {
    let x = maps[index].0
    LibPlacenote.instance.loadMap(mapId: maps[index].0,
                                  downloadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                                    if (completed) {
                                      self.mappingStarted = true //extending the map
                                      self.localizationStarted = true
                                      self.mapTable.isHidden = true
                                      self.pickMapButton.setTitle("Stop", for: .normal)
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
                                      let userdata = self.maps[index].1.userdata as? [String:Any]
                                      // This is placenote originally
                                      //                                      if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                      //                                        self.statusLabel.text = "Map Loaded. Look Around"
                                      //                                      }
                                      
                                      if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                        self.statusLabel.text = "Map Loaded. Look Around"
                                        //dump(userdata?["CheckpointDict"] as? [String:String])
                                        
                                      }
                                      else {
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
                                      print ("Couldnt load map: " + self.maps[index].0)
                                      self.statusLabel.text = "Load error Map Id: " +  self.maps[index].0
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
  
  func getClosetNode(camera_pos: SCNVector3, map: AdjacencyList<String>) -> Bool{
    if shapeManager.getShapePositions().count > 0 {
    for position in shapeManager.getShapePositions()
    {
      let pos = SCNV3toString(vec: position)

      let node = Hash_Node_Dict[pos]
      let tre = node?.geometry?.description
      if(tre != nil)
      {
        let T = Array(tre!)[4]
        if( T == "B")
        {
          
          if (nodeDistance(first: camera_pos, second: node?.position ?? SCNVector3(0.00, 0.00, 0.00)) < 1.5)
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
            dump("HEEEEEEREEEEE")
            return true
          }
        }
      }

      
      
    }
    }
    return false
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
      //updateGraph()
      
      locationManager.requestWhenInUseAuthorization()
      var currentLocation: CLLocation!
      
      if( CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
        CLLocationManager.authorizationStatus() ==  .authorizedAlways){
        
        currentLocation = locationManager.location
        let currentLat = currentLocation.coordinate.latitude
        let currentLong = currentLocation.coordinate.longitude
        
        let x = NSString(format: "%.8f", currentLat)
        let y = NSString(format: "%.8f", currentLong)
        let s3 = NSString(format:"%@,%@",x,y)
        let currentCLStr = s3 as String
        let cp_str = SCNV3toString(vec: loc02)
        Checkpoint_CL_Dict[cp_str] = currentCLStr
      }
      
      
//      // Testing
//      let dest = graph.adjacencyDict.keys.randomElement()
//      if dest != graph.adjacencyDict.keys.first {
//        let out = graph.aStar(start: graph.adjacencyDict.keys.first!, destination: dest!)
//        dump(out)
//        var outArray = ""
//
//        for vertex in out{
//          outArray = outArray+":"+vertex.description
//          print(outArray)
//        }
//        outArray.append("Start" + (graph.adjacencyDict.keys.first?.description)!)
//        outArray.append("End" + ((dest?.description)!))
//
//        let alert = UIAlertController(title: "Out", message: outArray, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
//          NSLog("The \"OK\" alert occured.")
//        }))
//        self.present(alert, animated: true, completion: nil)
        //
//      }
      
      
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

      //Pop up the drop destination window
      let DestinationName_alert = UIAlertController(title: "Enter Name of the Destination and Category", message: "Name it with a specific name, like 'Room 3320' and 'Study Room'", preferredStyle: UIAlertControllerStyle.alert)

      DestinationName_alert.addTextField(configurationHandler: {(textField: UITextField!) in
        textField.placeholder = "Enter Destination name:"
      })
      
      DestinationName_alert.addTextField(configurationHandler: {(textField: UITextField!) in
        textField.placeholder = "Enter Category:"
      })
      
      DestinationName_alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
        
        if let destination_name = DestinationName_alert.textFields?[0].text {
          Destination_array.append(destination_name) // Append to the destination array
          destination_name_meta = destination_name
          destination_pos = self.SCNV3toString(vec: loc02)
          Dest_Cat_Dict.removeAll()
          Dest_Pos_Dict[destination_name_meta] = destination_pos
        }
        
        if let category_name = DestinationName_alert.textFields?[1].text {
          Dest_Cat_Dict.removeAll()
          category_name_meta = category_name
          Dest_Cat_Dict[destination_name_meta] = category_name_meta
        }
        
      }))
      self.present(DestinationName_alert, animated: true, completion: nil)

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
  }
  
  func getClosestBC (camlocVec: SCNVector3) -> String {
    let shapePositions = shapeManager.getShapePositions()
    
    for vector3 in shapePositions {
      if ( nodeDistance(first: vector3, second: camlocVec) < 1.0 ){
        return SCNV3toString(vec:vector3)
      }
    }
    return ""
  }
  

    @IBAction func showPath(_ sender: Any) {
      // enable BC dropping
      canDropBC = false
      
      shapeManager.clearView()
      
      updateGraph()
//      print("This is the graph when showPath get called")
//      dump(graph)
      
      let dict = graph.adjacencyDict
      let vertices = dict.keys
      
    
      let shapePositions = shapeManager.getShapePositions()
      print("This is shapePosition")
      print(shapePositions)
      if (!shapePositions.isEmpty){
        print("This is the first in shapePosition list")
        dump(shapePositions[0])
        
        print("This is the nearest node now")
        dump(nearestShapes)
        
        // Set the first sphere as the start and last sphere as the destination
        let start = shapePositions[0] // type V3
        //let start = nearestShapes[0] // type V3
        let startStr = SCNV3toString(vec: start)
        
        let des = shapePositions[shapePositions.count-1] // type V3
        let desStr = SCNV3toString(vec: des)
        
//        let frame = scnView.session.currentFrame
//        let camera = frame?.camera
//        let loc = camera?.transform
//        let camloc = loc?.columns.3
//        let camlocV3 = SCNVector3(camloc!.x ,camloc!.y,camloc!.z)
//        //let camlocStr = SCNV3toString(vec: camlocV3)
//        var desStr = getClosestBC(camlocVec: camlocV3)
//        dump(desStr)
//        if desStr == "" {
//          desStr = SCNV3toString(vec: des)
//        }
//
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
        dump(startVer)
        dump(desVer)
        
        
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

}



