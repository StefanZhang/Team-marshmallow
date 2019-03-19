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

let AWSCognitoUserPoolsSignInProviderKey = "UserPool"
let userPoolID = "UserPool"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    class func defaultUserPool() -> AWSCognitoIdentityUserPool {
        return AWSCognitoIdentityUserPool(forKey: userPoolID)
    }
    
    var window: UIWindow?


    private var maps: [(String, LibPlacenote.MapMetadata)] = [("Sample Map", LibPlacenote.MapMetadata())]
    var MapName_array = [String]() //Array of Map Name
    var DestinationName_array = [String]() //Array of Destination Name
    var CategoryDict = [String:[String]]() //Dict with key of Category, and val of array of corresponding destination
    var MapDestDict = [String:[String]]() //Dict with key of Map Name, and val of array of corresponding Destiantion name
    var DestPosDict = [String:String]() // Dict with key of Destination Name, val of corresponding corrdinates
    
    // Dictionary for map location. key is mapname. value is lat+lon+alt
    var MapLocationDict = [String:String]()
    
    //AWS
    var storyboard: UIStoryboard?
    var navigationController: UINavigationController?
    var adminLoginViewController: AdminLoginViewController?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // setup logging
        AWSDDLog.sharedInstance.logLevel = .verbose
        
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
        let CognitoIdentityUserPoolRegion: AWSRegionType = .USEast2
        let CognitoIdentityUserPoolId = "us-east-2_eSmLbpR34"
        let CognitoIdentityUserPoolAppClientId = "2ohb870m9b8ecat963666vpj6e"
        let CognitoIdentityUserPoolAppClientSecret = "1a94e9itcfc25f4q33dj5oiv14sb850cb9jmuhfacohcej6avjk8"
        
        // Warn user if configuration not updated
        if (CognitoIdentityUserPoolId == "us-east-2_eSmLbpR34") {
            let alertController = UIAlertController(title: "Invalid Configuration",
                                                    message: "Please configure user pool constants in Constants.swift file.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            
            self.window?.rootViewController!.present(alertController, animated: true, completion:  nil)
        }
        
        // setup service configuration
        let serviceConfiguration = AWSServiceConfiguration(region: CognitoIdentityUserPoolRegion, credentialsProvider: nil)
        
        // create pool configuration
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: CognitoIdentityUserPoolAppClientId,
                                                                        clientSecret: CognitoIdentityUserPoolAppClientSecret,
                                                                        poolId: CognitoIdentityUserPoolId)
        // initialize user pool client
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: poolConfiguration, forKey: AWSCognitoUserPoolsSignInProviderKey)
        // fetch the user pool client we initialized in above step
        let pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        //self.storyboard = UIStoryboard(name: "Main", bundle: nil)
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
    func graphOfMaps() {
        let ultimateGraph = AdjacencyList<String>()
       
        //let mapLocArray = Array(MapLocationDict.values)
        var allVertices = [Vertex<String>]()
        
        for mapLoc in MapLocationDict.values {
            allVertices.append(ultimateGraph.createVertex(data: mapLoc))
        }
        let length = allVertices.count
        for i in 0..<length {
            for j in i+1..<length {
                ultimateGraph.add(.undirected, from:allVertices[i], to:allVertices[j], weight:1.5)
            }
        }
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
//        print("This is mapLocationDict")
//        dump(MapLocationDict)
        
//        print("CategoryDict: Category(Key), with Destination(val)")
//        print(CategoryDict)
//        print("MapDestDict: MapName(Key), with Destination(val)")
//        print(MapDestDict)
//        print("DestPosDict: DestinationName(Key), with Position(val)")
//        print(DestPosDict)

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
    
//    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
//        if (self.navigationController == nil) {
//            self.navigationController = self.window?.rootViewController as? UINavigationController
//        }
//        
//        if (self.adminLoginViewController == nil) {
//            self.adminLoginViewController = self.storyboard?.instantiateViewController(withIdentifier: "adminLoginViewController") as? AdminLoginViewController
//        }
//        
//        DispatchQueue.main.async {
//            //self.navigationController!.popToRootViewController(animated: true)
//            if(self.adminLoginViewController!.isViewLoaded || self.adminLoginViewController!.view.window == nil) {
//                self.navigationController?.present(self.adminLoginViewController!, animated: true, completion: nil)
//            }
//            
//        }
//        return self.adminLoginViewController!
//    }
    
    
    func startRememberDevice() -> AWSCognitoIdentityRememberDevice {
        return self as! AWSCognitoIdentityRememberDevice
    }
}
