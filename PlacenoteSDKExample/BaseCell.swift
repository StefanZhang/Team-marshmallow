//
//  BaseCell.swift
//  PlacenoteSDKExample
//
//  Created by xiaofeng Zhang on 3/20/19.
//  Copyright © 2019 Vertical. All rights reserved.
// 
//  Parent function of all cells

import UIKit

class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
