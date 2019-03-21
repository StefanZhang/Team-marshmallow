//
//  MenuCellWT.swift
//  PlacenoteSDKExample
//
//  Created by xiaofeng Zhang on 3/20/19.
//  Copyright © 2019 Vertical. All rights reserved.
//
//  Customized Cell function for Menu, inherite from Base Cell

import UIKit

class MenuCell: BaseCell {
    
    // Handle when the button is being clikced, the color changing to the front , background and the icon
    override var isHighlighted: Bool {
        didSet{
            backgroundColor = isHighlighted ? UIColor.darkGray : UIColor.white
            namelabel.textColor = isHighlighted ? UIColor.white : UIColor.darkGray
            iconimageview.tintColor = isHighlighted ? UIColor.white : UIColor.darkGray
        }
    }
    
    var menu : MenuObject?{
        didSet{
            namelabel.text = menu?.name
            iconimageview.image = UIImage(named: (menu?.imgName)!)?.withRenderingMode(.alwaysTemplate)
            iconimageview.tintColor = UIColor.darkGray
        }
    }
    
    let namelabel: UILabel = {
        let label = UILabel()
        label.text = "Admin Login"
        return label
    }()
    
    let iconimageview: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "settings")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    // This is where add label and icon to the menu cell
    override func setupViews() {
        super.setupViews()
        //backgroundColor = UIColor.blue
        
        addSubview(namelabel)
        addSubview(iconimageview)
        
        // Add horizontal constrans to namelabel and icon
        addConstraintsWithFormat(format: "H:|-8-[v0(25)]-8-[v1]|", views: iconimageview, namelabel)
        
        // Add vertical constrans to namelabel and icon
        addConstraintsWithFormat(format: "V:|[v0]|", views: namelabel)
        
        // add height to icon
        addConstraintsWithFormat(format: "V:|[v0(25)]|", views: iconimageview)
        
        //addConstraint(NSLayoutConstraint(item: iconimageview, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
    }
}
