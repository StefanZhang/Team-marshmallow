//
//  ViewControllerWT.swift
//  PlacenoteSDKExample
//
//  Created by Team Herman Miller on 2/12/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import UIKit
import PlacenoteSDK

var Destination_array = [String]() // Store Destination Name

class ViewControllerWT: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var pickerView: UIPickerView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var tempArray = ["Fetching Places..."]
    var search = [String]()
    var searching = false
    var selectedPlace = ""
    var pickerData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SetUpLeftNaviBar()
        pickerData = ["all places","bathroom","classroom"]
        tempArray.sort() // sorts list of places
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        //navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
    }
    
    
    func SetUpLeftNaviBar(){
        let MenuButton = UIBarButtonItem(image: UIImage(named: "menu_icon"), style: .plain, target: self, action: #selector(ShowMenu))
    
        navigationItem.leftBarButtonItem = MenuButton
        
    }
    
    
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        //super.viewWillAppear(animated)
        //navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //super.viewWillDisappear(animated)
        //navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching{
            return search.count
        }
        else{
            return tempArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")
        if searching{
            cell?.textLabel?.text = search[indexPath.row]
        }
        else{
            cell?.textLabel?.text = tempArray[indexPath.row]
        }
        return cell!
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        search = tempArray.filter({$0.lowercased().prefix(searchText.count) == searchText.lowercased()})
        searching = true
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searching == false{
            selectedPlace = self.tempArray[indexPath.row]
        }
        else{
            selectedPlace = self.search[indexPath.row]
            self.searchBarCancelButtonClicked(searchBar)
            // to highlight the selected row after selecting it from a search
            let indexPath2 = IndexPath(row: tempArray.firstIndex(of: selectedPlace)!, section: 0)
            self.tableView.selectRow(at: indexPath2, animated: true, scrollPosition: UITableViewScrollPosition.middle)
            // still a shadow after the row is selected
            // only after using search to find place
        }
        print(selectedPlace)
        print(appDelegate.WhichMapANDWhichPos(DestName: selectedPlace))
    }
    
    func getSelectedPlace() -> String{
        return self.selectedPlace
    }
    
    func setPlaceArray(_ array: [String]){
        tempArray = array
        let farray = tempArray.filter {$0 != "DefaultDest"}
        tempArray = farray
        tempArray.sort()
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            self.setPlaceArray(self.appDelegate.getDestinationName())
        })
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // determines the number of rows in the picker view
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // Populates each row of the picker view
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return pickerData[row]
    }
    
    // Sets up the font displayed in the filter picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: "Times New Roman", size: 16)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = pickerData[row]
        pickerLabel?.textColor = UIColor.black
        
        return pickerLabel!
    }
    
    // when picker view function is changed
    // filters the main table view
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(pickerData[row])
        var tempDict = appDelegate.getCategoryDict()
        if (pickerData[row] == "all places"){
            self.setPlaceArray(self.appDelegate.getDestinationName())
        }
        else{
            self.setPlaceArray(tempDict[pickerData[row]]!)
        }
    }
    
}
