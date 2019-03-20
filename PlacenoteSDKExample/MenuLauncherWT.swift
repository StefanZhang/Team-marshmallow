//
//  MenuLauncher.swift
//  PlacenoteSDKExample
//
//  Created by xiaofeng Zhang on 3/20/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import Foundation
import UIKit

class MenuLauncher: NSObject {
    
    // This function handles two things:
    // 1. Black(gray) out the screen other then the menu with animation
    // 2. Display the menu
    let blackview = UIView()
    
    let collectionview: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let colview = UICollectionView(frame: .zero, collectionViewLayout: layout)
        colview.backgroundColor = UIColor.white
        return colview
    }()
    
    @objc func ShowMenu(){
        
        if let window = UIApplication.shared.keyWindow{
            
            blackview.backgroundColor = UIColor(white: 0, alpha: 0.5)
            
            blackview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(HandleDismiss)))
            
            window.addSubview(blackview)
            window.addSubview(collectionview)
            
            collectionview.frame = CGRect(x: 0, y: 0, width: 200, height: window.frame.height)
            
            blackview.frame = window.frame
            self.blackview.alpha = 0
            
            UIView.animate(withDuration: 0.5, animations: {
                self.blackview.alpha = 1
                self.collectionview.frame = CGRect(x: 0, y: 0, width: self.collectionview.frame.width, height: self.collectionview.frame.height)
            })
        }
    }
    
    @objc func HandleDismiss(){
        UIView.animate(withDuration: 0.5, animations: {
            self.blackview.alpha = 0
            
            if let window = UIApplication.shared.keyWindow{
                self.collectionview.frame = CGRect(x: 0, y: self.collectionview.frame.height, width: self.collectionview.frame.width, height: self.collectionview.frame.height)
            }
        })
    }
    
    
    
    
    override init() {
        super.init()
    }
    
    
}
