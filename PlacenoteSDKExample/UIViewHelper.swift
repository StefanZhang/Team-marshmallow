//
//  HelperExtenstion.swift
//  PlacenoteSDKExample
//
//  Created by xiaofeng Zhang on 3/20/19.
//  Copyright © 2019 Vertical. All rights reserved.
//  Helper function that allows to use apple constraints faster

import UIKit

extension UIView {
    func addConstraintsWithFormat(format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
}

