//
//  MenuLauncher.swift
//  PlacenoteSDKExample
//
//  Created by xiaofeng Zhang on 3/20/19.
//  Copyright © 2019 Vertical. All rights reserved.
//
// Helper Launcher class for Menu in WTcontroller, to reduce the code in controller
// 1. Black(gray) out the screen other then the menu with animation
// 2. Display the menu

import Foundation
import UIKit

// handle the info of each menu object, name being the bar name, and the imgName is icon name
class MenuObject: NSObject {
    let name: String
    let imgName: String
    
    init(name: String, imgName: String) {
        self.name = name
        self.imgName = imgName
    }
}

class MenuLauncher: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // Black out the sreen
    let blackview = UIView()
    
    var ViewControllerWT: ViewControllerWT?
    
    //var ViewController: ViewController?
    
    let collectionview: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let colview = UICollectionView(frame: .zero, collectionViewLayout: layout)
        colview.backgroundColor = UIColor.white
        return colview
    }()
    
    let cellID = "cellID"
    
    // Contains all the menu obejct
    let MenuObjects: [MenuObject] = {
        return [MenuObject(name: "Admin Login", imgName: "settings"), MenuObject(name: "User Instructions", imgName: "like"), MenuObject(name: "About HermanMiller", imgName: "home")]
    }()
    
    // Display menu with specific coordinates and animation
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
    
    // Fade out animation
    @objc func HandleDismiss(){
        UIView.animate(withDuration: 0.5, animations: {
            self.blackview.alpha = 0
            
            if let window = UIApplication.shared.keyWindow{
                self.collectionview.frame = CGRect(x: 0, y: self.collectionview.frame.height, width: self.collectionview.frame.width, height: self.collectionview.frame.height)
            }
        })
    }
    
    // set the number of cells will be display in menu bar
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MenuObjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! MenuCell
        
        let menu = MenuObjects[indexPath.item]
        cell.menu = menu
        
        return cell
    }
    
    // set the width and height of the cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 30)
    }
    
    // reduce gap between cells (defualt 10)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    // handle the menu selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let menu = MenuObjects[indexPath.item]
        
        if menu.name == "Admin Login"{
            let view = ViewControllerWT
            view?.adminMode.sendActions(for: .touchUpInside)
            HandleDismiss()
        }
        if menu.name == "User Instructions"{
            print("instruction")
        }
        if menu.name == "About HermanMiller"{
            print("about")
        }
        
    }
    
    override init() {
        super.init()
        
        collectionview.dataSource = self
        collectionview.delegate = self
        collectionview.register(MenuCell.self, forCellWithReuseIdentifier: cellID)
    }
}
