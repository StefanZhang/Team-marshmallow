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
import AWSCognito

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var maps: [(String, LibPlacenote.MapMetadata)] = [("Sample Map", LibPlacenote.MapMetadata())]
    var MapName_array = [String]()
    var DestinationName_array = [String]()
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // AWS initialization
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast2,
                                                                identityPoolId:"us-east-2:f1c35eed-faab-4fc0-8e34-d205684e0916")
        
        let configuration = AWSServiceConfiguration(region:.USEast2, credentialsProvider:credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration

        
        LibPlacenote.instance.initialize(apiKey: "0qmcrb5a2tw2b00xa70d1x81sae3k9dtvu4fq9mf9zlpoqcwzozmy8d1k8kpfag32abvfo3ql5tu059np1xt74zsfprhrurzui2k",  onInitialized: {(initialized: Bool?) -> Void in
            if (initialized!) {
                print ("SDK Initialized")
                LibPlacenote.instance.fetchMapList(listCb: self.onMapList)
            }
            else {
                print ("SDK Could not be initialized")
            }
        })
        return true
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
        
        var Name_DestinationDict = [String:String]()
        
        for item in maps{
            MapName_array.append(item.1.name ?? "")
            let userdata = item.1.userdata as? [String:Any]
            Name_DestinationDict = userdata!["destinationDict"] as! Dictionary
            
            for (key, value) in Name_DestinationDict {
                DestinationName_array.append(key)
            }
        
        }
        
        print(DestinationName_array)
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
    
    
}

