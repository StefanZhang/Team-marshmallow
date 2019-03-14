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
import AWSCognitoIdentityProvider

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?


    private var maps: [(String, LibPlacenote.MapMetadata)] = [("Sample Map", LibPlacenote.MapMetadata())]
    var MapName_array = [String]()
    var DestinationName_array = [String]()
    var CategoryDict = [String:[String]]()
    
    //AWS
    var storyboard: UIStoryboard?
    var navigationController: UINavigationController?
    var adminLoginViewController: AdminLoginViewController?
    

    
    let AWSCognitoUserPoolsSignInProviderKey = "UserPool"
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // setup logging
        AWSDDLog.sharedInstance.logLevel = .verbose
        
        // AWS Cognito initialization
        setCognitoUserPool()
        
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
        var Destination_CatDict = [String:String]()
        
        for map in maps{
            MapName_array.append(map.1.name ?? "")
            let userdata = map.1.userdata as? [String:Any]
            
            // This was crashing the app!! Dictionary was nil
            //Name_DestinationDict = userdata!["destinationDict"] as! Dictionary
            
            // Replaced with this in order to build without crashing
            Name_DestinationDict = userdata!["destinationDict"] as? Dictionary<String, String> ?? ["DefaultDest" : "N/A"]
            
            for (key, value) in Name_DestinationDict {
                DestinationName_array.append(key)
            }
            
            Destination_CatDict = userdata!["CategoryDict"] as? Dictionary<String, String> ?? ["DefualtDest" : "DefaultCat"]
            
            for (Dest,Cat) in Destination_CatDict {
                print(Cat,Dest)
                if (CategoryDict[Cat] != nil){
                    print("Cat exsists, append the name to the back of the val list")
                    CategoryDict[Cat]!.append(Dest)
                }
                else{
                    print("Cat does not exsists, create one, and add the name to the val list")
                    CategoryDict[Cat] = [Dest]
                }
            }
        }
        
        print(CategoryDict)
        print("Destination Name array: ")
        print(DestinationName_array)
        
        //Clear the previous user info to avoid duplicates
        
        
        
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

// AWS
extension AppDelegate: AWSCognitoIdentityInteractiveAuthenticationDelegate {
    
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        if (self.navigationController == nil) {
            self.navigationController = self.storyboard?.instantiateViewController(withIdentifier: "adminLoginViewController") as? UINavigationController
        }
        
        if (self.adminLoginViewController == nil) {
            self.adminLoginViewController = self.navigationController?.viewControllers[0] as? AdminLoginViewController
        }
        
        DispatchQueue.main.async {
            self.navigationController!.popToRootViewController(animated: true)
            if (!self.navigationController!.isViewLoaded
                || self.navigationController!.view.window == nil) {
                self.window?.rootViewController?.present(self.navigationController!,
                                                         animated: true,
                                                         completion: nil)
            }
            
        }
        return self.adminLoginViewController!
    }
    
    
    func startRememberDevice() -> AWSCognitoIdentityRememberDevice {
        return self as! AWSCognitoIdentityRememberDevice
    }
}
