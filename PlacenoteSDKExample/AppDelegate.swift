//
//  AppDelegate.swift
//  Shape Dropper (Placenote SDK iOS Sample)
//
//  Created by Prasenjit Mukherjee on 2017-09-01.
//  Copyright © 2017 Vertical AI. All rights reserved.
//

import UIKit
import PlacenoteSDK
import AWSCore
import AWSCognitoIdentityProvider
import CoreLocation

let AWSCognitoUserPoolsSignInProviderKey = "UserPool"
let userPoolID = "UserPool"

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    class func defaultUserPool() -> AWSCognitoIdentityUserPool {
        return AWSCognitoIdentityUserPool(forKey: userPoolID)
    }
    
    var window: UIWindow?


    var maps: [(String, LibPlacenote.MapMetadata)] = [("Sample Map", LibPlacenote.MapMetadata())]
    var MapName_array = [String]() //Array of Map Name
    var DestinationName_array = [String]() //Array of Destination Name
    var CategoryDict = [String:[String]]() //Dict with key of Category, and val of array of corresponding destination
    var MapDestDict = [String:[String]]() //Dict with key of Map Name, and val of array of corresponding Destiantion name
    var DestPosDict = [String:String]() // Dict with key of Destination Name, val of corresponding corrdinates
    var ultimateGraph = AdjacencyList<String>() // Graph for all the maps. used in ultimate navigation
    
    var allVertices = [Vertex<String>]()
    // Dictionary for map location. key is mapname. value is lat+lon+alt
    var MapLocationDict = [String:String]()
    
    //AWS
    var storyboard: UIStoryboard? {
        return UIStoryboard(name: "Main", bundle: nil)
    }
    var navigationController: UINavigationController?
    var loginViewController: AdminLoginViewController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // setup AWS logging
        AWSDDLog.sharedInstance.logLevel = .verbose
        AWSDDLog.add(AWSDDTTYLogger.sharedInstance)
        
        // AWS Cognito initialization
        setCognitoUserPool()
        
        LibPlacenote.instance.initialize(apiKey: "0qmcrb5a2tw2b00xa70d1x81sae3k9dtvu4fq9mf9zlpoqcwzozmy8d1k8kpfag32abvfo3ql5tu059np1xt74zsfprhrurzui2k",  onInitialized: {(initialized: Bool?) -> Void in
            if (initialized!) {
                print ("PlaceNote SDK Initialized")
                LibPlacenote.instance.fetchMapList(listCb: self.onMapList)
            }
            else {
                print ("Placenote SDK Could not be initialized")
            }
        })
        return true
    }
    
    func setCognitoUserPool() {
        
        let clientId:String = "2ohb870m9b8ecat963666vpj6e"
        let poolId:String = "us-east-2_eSmLbpR34"
        let clientSecret:String = "1a94e9itcfc25f4q33dj5oiv14sb850cb9jmuhfacohcej6avjk8"
        let region:AWSRegionType = .USEast2
        
        let serviceConfiguration:AWSServiceConfiguration = AWSServiceConfiguration(region: region, credentialsProvider: nil)
        let cognitoConfiguration:AWSCognitoIdentityUserPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: clientId, clientSecret: clientSecret, poolId: poolId)
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: cognitoConfiguration, forKey: userPoolID)
        let pool:AWSCognitoIdentityUserPool = AppDelegate.defaultUserPool()
        pool.delegate = self
    }
    
    func mapLocToString(lat: Double, lon: Double, alt: Double) -> String{
        let x = NSString(format: "%.16f", lat)
        let y = NSString(format: "%.16f", lon)
        let z = NSString(format: "%.16f", alt)
        let s3 = NSString(format:"%@,%@,%@",x,y,z)
        let resultString = s3 as String
        return resultString
    }

    // for ultimate navigation
    func createGraphOfMaps() {
        //let ultimateGraph = AdjacencyList<String>()
       
        //let mapLocArray = Array(MapLocationDict.values)
        
        
        for mapLoc in MapLocationDict.values {
            allVertices.append(ultimateGraph.createVertex(data: mapLoc))
        }
        let length = allVertices.count
        for i in 0..<length {
            for j in i+1..<length {
                ultimateGraph.add(.undirected, from:allVertices[i], to:allVertices[j], weight:1.5)
            }
        }
//        print("This is the ultimate graph")
//        dump(ultimateGraph)
        // later will be moved into the user navigation viewcontroller
//        if (!allVertices.isEmpty){
//            let maps = aStarForMaps(start: allVertices.first!, destination: allVertices.last!)
//            dump(maps)
//            
//        }
        
    }
    

    func edges(from source: Vertex<String>) -> [Edge<String>]? {
        return ultimateGraph.adjacencyDict[source]
    }
    
    func findNeighborsMaps(node: Vertex<String>) -> Array<Vertex<String>> {
        var neighbors = Array<Vertex<String>>()
        let edge_list = edges(from: node)
        for edge in edge_list! {
            //dump(edge.destination.description)
            neighbors.append(edge.destination)
        }
        return neighbors
    }
    
    func reconstructPathOfMaps(cameFrom: Dictionary<String,Vertex<String>>, currentVertex:Vertex<String>) -> Array<Vertex<String>> {
        var current = currentVertex
        var total_path = [current]
        while (cameFrom[current.description] != nil) {
            current = cameFrom[current.description]!
            total_path.append(current)
        }
        return total_path
    }
    func pathOrder(custommaps: [(String, LibPlacenote.MapMetadata)]) -> [Double]
    {
        var locations = [[Double]]()
        for map in custommaps
        {
            locations.append([map.1.location!.latitude,map.1.location!.longitude])
        }
        
        var latSplit = 0
        var longSplit = 0
        
        let firstLat = String(locations[0][0])
        let secLat   = String(locations[1][0])
        let thLat    = String(locations[2][0])
        let FLat = Array(firstLat)
        let SLat = Array(secLat)
        let TLat = Array(thLat)
        while FLat[latSplit] == SLat[latSplit] && FLat[latSplit] == TLat[latSplit]
        {
            latSplit += 1
        }
        var latitude = ""
        
        for digit in FLat[latSplit..<FLat.count-1]
        {
            latitude += String(digit)
        }
        dump(latitude)
        return locations[0]
    }
    
    // aStar algorithm for ultimate navigation
    func aStarForMaps(start: Vertex<String>, destination: Vertex<String>) -> Array<Vertex<String>> {
        let mapinfo = maps
        let x = pathOrder(custommaps: mapinfo)
        let graphDict = ultimateGraph.adjacencyDict
        
        var keyStrs = [String]()
        for vertex in graphDict.keys {
            keyStrs.append(vertex.description)
        }
        
        var out = Array<Vertex<String>>()
        var frontier: Array<Vertex<String>> = [start]
        var cameFrom = Dictionary<String,Vertex<String>> ()
        var g = Dictionary<String,Double> ()
        for str in keyStrs {
            g[str] = Double.infinity
        }
        // The cost of going from start to start is zero.
        g[start.description] = 0.0
        var f = Dictionary<String,Double> ()
        for str in keyStrs {
            f[str] = Double.infinity
        }
        f[start.description] = 1000 //is this right?
        while frontier.count > 0 {
            
            // current := the node in openSet having the lowest fScore[] value
            // current is vertex type
            var frontierMin = frontier[0]
            for fr in frontier{
                if (f[fr.description] ?? 0 < f[frontierMin.description] ?? 0){
                    frontierMin = fr
                }
            }
            let current = frontierMin //might be wrong
            
            
            //if current = goal
            if current == destination {
                //return reconstruct_path(cameFrom, current)
                //                print("Final G score dictionary")
                //                print(g)
                return reconstructPathOfMaps(cameFrom: cameFrom, currentVertex: current)
                
            }
            
            //openSet.Remove(current)
            let currentIndex = frontier.firstIndex(of: current)
            frontier.remove(at: currentIndex!)
            //closedSet.Add(current)
            out.append(current)
            
            for neighbor in findNeighborsMaps(node: current) {
                //                print("This is the first neighbor of current")
                //                dump(neighbor)
                
                //if neighbor in closedSet(Out)
                //continue
                // Ignore the neighbor which is already evaluated.
                if out.contains(neighbor){
                    continue
                }
                
                // The distance from start to a neighbor
                // tentative_gScore := gScore[current] + dist_between(current, neighbor)
                let tentative_gScore = g[current.description]! + mapDistance(first: current.description, second: neighbor.description)
                
                //if neighbor not in openSet    // Discover a new node
                //openSet.Add(neighbor)
                
                if !frontier.contains(neighbor) {
                    frontier.append(neighbor)
                }
                else if (tentative_gScore >= g[neighbor.description]!) {
                    continue
                }
                
                cameFrom[neighbor.description] = current
                g[neighbor.description] = tentative_gScore
                f[neighbor.description] = g[neighbor.description]! + mapDistance(first: neighbor.description,second: destination.description)
                
            }
        }
        print("Failure")
        return Array<Vertex<String>>()
    }
    
    func mapDistance(first:String, second: String) -> Double {
        let strArray = first.split(separator: ",")
        let strArray2 = second.split(separator: ",")
        let x1 = Double(strArray[0]) ?? 0.0
        let y1 = Double(strArray[1]) ?? 0.0
        //let z1 = Double(strArray[2]) ?? 0.0
        let x2 = Double(strArray2[0]) ?? 0.0
        let y2 = Double(strArray2[1]) ?? 0.0
        //let z2 = Double(strArray2[2]) ?? 0.0
        
        let firstCD = CLLocation(latitude: x1, longitude: y1)
        let secondCD = CLLocation(latitude: x2, longitude: y2)
        
        let distance = firstCD.distance(from: secondCD)
        return distance
    }
    
    //Receive list of maps after it is retrieved. This is only fired when fetchMapList is called (see updateMapTable())
    func onMapList(success: Bool, mapList: [String: LibPlacenote.MapMetadata]) -> Void {
        maps.removeAll()
        if (!success) {
            print ("failed to fetch map list")
            return
        }

        
        //Cycle through the maplist and create a database of all the maps (place.key) and its metadata (place.value)
        for place in mapList {
            maps.append((place.key, place.value))
        }
        
        var Name_DestinationDict = [String:String]() //temp container
        var Destination_CatDict = [String:String]() // temp container
        var Destination_PosDict = [String:String]() //temp container
        
        for map in maps{
            let MapNametemp = map.1.name ?? ""
            MapName_array.append(MapNametemp)
            let userdata = map.1.userdata as? [String:Any]

            //for ultimate navigation
            let mapLat = map.1.location?.latitude
            let mapLon = map.1.location?.longitude
            let mapAlt = map.1.location?.altitude
            let mapLocStr = mapLocToString(lat: mapLat!, lon: mapLon!, alt: mapAlt!)
            MapLocationDict[MapNametemp] = mapLocStr
            
            Name_DestinationDict = userdata!["destinationDict"] as? Dictionary<String, String> ?? ["DefaultDest" : "N/A"]
            
            for (key, value) in Name_DestinationDict {
                DestinationName_array.append(key)
                
                if (MapDestDict[MapNametemp] != nil){
                    MapDestDict[MapNametemp]!.append(key)
                }
                else{
                    MapDestDict[MapNametemp] = [key]
                }
            }
            
            Destination_CatDict = userdata!["CategoryDict"] as? Dictionary<String, String> ?? ["DefualtDest" : "DefaultCat"]
            
            for (Dest,Cat) in Destination_CatDict {
                if (CategoryDict[Cat] != nil){
                    // Cat exsists, append the name to the back of the val list
                    CategoryDict[Cat]!.append(Dest)
                }
                else{
                    // Cat does not exsists, create one, and add the name to the val list
                    CategoryDict[Cat] = [Dest]
                }
            }
            
            Destination_PosDict = userdata!["destinationDict"] as? Dictionary<String, String> ?? ["DefualtDest" : "DefaultPos"]
            
            for (Dest, Pos) in Destination_PosDict{
                DestPosDict[Dest] = Pos
            }
            
        }
        // for ultimate navigation
        createGraphOfMaps()
        
//        print("This is mapLocationDict")
//        dump(MapLocationDict)
        
//        print("CategoryDict: Category(Key), with Destination(val)")
//        print(CategoryDict)
        print("MapDestDict: MapName(Key), with Destination(val)")
        print(MapDestDict)
        print("DestPosDict: DestinationName(Key), with Position(val)")
        print(DestPosDict)

    }
    
    func getMapLocationDict() -> [String:String] {
        return MapLocationDict
    }
    
    func getCategoryDict() -> [String:[String]] {
        return CategoryDict
    }
    
    // Getter for Destination Names
    func getDestinationName() -> [String] {
        return DestinationName_array
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        LibPlacenote.instance.shutdown()
    }
    
    // Input Destination Name
    // Return the result array with result[0] = MapName and result[1] = Position
    func WhichMapANDWhichPos(DestName:String) -> [String]{
        var result = [String]()
        
        result.append(WhichMap(DestName: DestName))
        result.append(DestPosDict[DestName]!)

        return result
    }
    
    func WhichMap(DestName:String) -> String {
        var result = ""
        
        for (Map, Dest) in MapDestDict{
            for i in Dest{
                if i == DestName{
                    result = Map
                    break
                }
            }
        }
        return result
    }
    
    
}

// AWS
extension AppDelegate: AWSCognitoIdentityInteractiveAuthenticationDelegate {
    
    
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        if(self.navigationController == nil) {
            self.navigationController = self.window?.rootViewController as? UINavigationController
        }
        
        if(self.loginViewController == nil) {
            self.loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "adminLoginViewController") as? AdminLoginViewController
        }
        
        DispatchQueue.main.async {
            if(self.loginViewController!.isViewLoaded || self.loginViewController!.view.window == nil) {
                self.navigationController?.pushViewController(self.loginViewController!, animated: true)
            }
        }
        
        return self.loginViewController!
    }
    
//    func startNewPasswordRequired() -> AWSCognitoIdentityNewPasswordRequired {
//        if (self.resetPasswordViewController == nil) {
//            self.resetPasswordViewController = self.storyboard?.instantiateViewController(withIdentifier: "adminLoginViewController") as? AdminLoginViewController
//        }
//
//        DispatchQueue.main.async {
//            if(self.resetPasswordViewController!.isViewLoaded || self.resetPasswordViewController!.view.window == nil) {
//                self.navigationController?.present(self.resetPasswordViewController!, animated: true, completion: nil)
//            }
//        }
//
//        return self.resetPasswordViewController!
//    }
    //    func startRememberDevice() -> AWSCognitoIdentityRememberDevice {
    //        return self as! AWSCognitoIdentityRememberDevice
    //    }
}
