//
//  ViewControllerUM.swift
//  PlacenoteSDKExample
//
//  Created by Team Herman Miller on 3/21/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import UIKit
import ARKit

class ViewControllerUM: UIViewController {

    @IBOutlet var userView: ARSCNView!
    let config = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        userView.session.run(config)
        
        // Do any additional setup after loading the view.
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
