//
//  NavigationNode.swift
//  PlacenoteSDKExample
//
//  Created by Team Herman Miller on 1/30/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import Foundation
import SceneKit


class NavigationNode {
    var type: Double
    var position: SCNVector3
    init(type: Double, position: SCNVector3){
        self.type     = type
        self.position = position
    }
    
}
