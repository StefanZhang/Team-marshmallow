//
//  MapSort.swift
//  PlacenoteSDKExample
//
//  Created by Team Herman Miller on 3/15/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import Foundation

// Going to sort all the maps outputted by Zhenru with this and load them in order
func quickmapsort<T: Comparable>(_ a: [T]) -> [T] {
    guard a.count > 1 else { return a }
    
    let pivot = a[a.count/2]
    let less = a.filter { $0 < pivot }
    let equal = a.filter { $0 == pivot }
    let greater = a.filter { $0 > pivot }
    
    return quickmapsort(less) + equal + quickmapsort(greater)
}
