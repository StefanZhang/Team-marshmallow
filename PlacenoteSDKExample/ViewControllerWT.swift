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
    
    @IBOutlet weak var adminMode: UIButton!
    @IBOutlet weak var UserIns: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var btnGo: UIButton!
    @IBOutlet weak var fpbutton: UIButton!
    @IBOutlet weak var about: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var tempArray = ["Fetching Places..."] // placeholder when fetching array
    var search = [String]()
    var searching = false // if the user is searching
    var selectedPlace = "" // place that the user picked to go
    var pickerData: [String] = [String]() // to populate the pickerview
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pickerView.isHidden = true // hide the pickerview until the tableview is loaded
        self.segmentedControl.isHidden = true
        self.btnGo.isHidden = true
        self.adminMode.isHidden = true
        self.UserIns.isHidden = true
        self.about.isHidden = true
        self.fpbutton.isHidden = true
        SetUpLeftNaviBar() // shows navigation bar
        SetUpRightNaviBar()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        pickerData = ["All Places","Bathrooms","Campsite","Coats","Collaboration Area","Concierge","Conference Rooms","Courtyard","Customer Expierence","Entry","Mail/Print/Copy/Fax","Lockers","Phone Room","Project Room","Refreshments","Shelter","Other"] // types of places, hardcoded (for now)
        tempArray.sort() // sorts list of places
        // setup delegates and data sources
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        //navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundBlur")!)
        searchBar.isUserInteractionEnabled = false
        tableView.isUserInteractionEnabled = false
    }
    
    func SetUpLeftNaviBar(){
        let MenuButton = UIBarButtonItem(image: UIImage(named: "menu_icon"), style: .plain, target: self, action: #selector(ShowMenu))
        navigationItem.leftBarButtonItem = MenuButton
    }
    
    func SetUpRightNaviBar(){
        let logoImage = UIImage(named: "hmCircleLogo")?.withRenderingMode(.alwaysOriginal)
        let logoButton = UIBarButtonItem(image: logoImage, style: .plain, target: self, action: #selector(aboutHM))
        logoButton.imageInsets = UIEdgeInsets(top: 0, left: 525, bottom: 00, right: 00)
        navigationItem.rightBarButtonItem = logoButton
    }
    
    let menuLauncher = MenuLauncher()
    
    
    @objc func aboutHM(){
        self.about.sendActions(for: .touchUpInside)
    }

    // This function get called once the menu botton is being hit
    // 1. Black(gray) out the screen other then the menu with animation
    // 2. Display the menu
    @objc func ShowMenu(){
        menuLauncher.ViewControllerWT = self
        menuLauncher.ShowMenu()
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
            // how many items are in the tableview while the user is searching
            return search.count
        }
        else{
            // while the user isn't searching
            return tempArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")
        // populates each cell within the tableview
        if searching{
            cell?.textLabel?.text = search[indexPath.row]
        }
        else{
            cell?.textLabel?.text = tempArray[indexPath.row]
        }
        cell?.textLabel?.font = UIFont(name: "Ariel", size: 20)
        cell?.textLabel?.textAlignment = .center
        return cell!
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        // if searchbar is being used
        search = tempArray.filter({$0.lowercased().prefix(searchText.count) == searchText.lowercased()})
        searching = true
        if (self.pickerView.isHidden == false){
            self.pickerView.isHidden = true
            self.tableView.isHidden = false
            segmentedControl.selectedSegmentIndex = 0
        }
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // when the cancel button on the search bar is clicked
        searching = false
        searchBar.text = ""
        self.searchBar.endEditing(true)
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.btnGo.isHidden = false
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
        self.searchBar.endEditing(true)
        //self.searchBarShouldEndEditing(searchBar)
        //print(selectedPlace)
        //print(appDelegate.WhichMapANDWhichPos(DestName: selectedPlace))
    }
    
    func getSelectedPlace() -> String{
        return self.selectedPlace
    }
    
    // used to set up/ update the tableview that holds destinations
    func setPlaceArray(_ array: [String]){
        tempArray = array
        // eliminates defaultdest
        let farray = tempArray.filter {$0 != "DefaultDest"}
        tempArray = farray
        tempArray.sort() // sorts it
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        var counter = 0
        weak var timer: Timer?
        var needtimer = true
        
        if self.appDelegate.getDestinationName().count > 1 {
            // do stuff after destinations load in here
            needtimer = false
            // Array(Set()) is used around the array to make sure there are no duplicate values
            self.setPlaceArray(Array(Set(self.appDelegate.getDestinationName())))
            // show segmented control when table loads
            self.segmentedControl.isHidden = false
            // allow users to search
            self.searchBar.isUserInteractionEnabled = true
            self.tableView.isUserInteractionEnabled = true
        }
        
        // loops every second to see if destinations can be loaded
        if needtimer == true{
            timer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                         repeats: true) {
                                            theTimer in
                                            counter += 1
                                            print(counter)
                                            if self.appDelegate.getDestinationName().count > 1 {
                                                // do stuff after destinations load in here
                                                
                                                // Array(Set()) is used around the array to make sure there are no duplicate values
                                                self.setPlaceArray(Array(Set(self.appDelegate.getDestinationName())))
                                                // show segmented control when table loads
                                                self.segmentedControl.isHidden = false
                                                // allow users to search
                                                self.searchBar.isUserInteractionEnabled = true
                                                self.tableView.isUserInteractionEnabled = true
                                                theTimer.invalidate()
                                            }
            }
        }
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
            pickerLabel?.font = UIFont(name: "Ariel", size: 20)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = pickerData[row]
        pickerLabel?.textColor = UIColor.black
        
        return pickerLabel!
    }
    
    // when picker view function is changed
    // filters the main table view
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tableView.isUserInteractionEnabled = true
        print(pickerData[row])
        var tempDict = appDelegate.getCategoryDict()
        if (pickerData[row] == "All Places"){ // used to display all places
            // Array(Set()) is used around the array to make sure there are no duplicate values
            self.setPlaceArray(Array(Set(self.appDelegate.getDestinationName())))
        }
        else{ // filters by the type of destination the user wants
            if tempDict[pickerData[row]] != nil{
                self.setPlaceArray(tempDict[pickerData[row]]!)
            }
            else{
                print("places dont exist")
                self.setPlaceArray(["No Places Found"])
                tableView.isUserInteractionEnabled = false
            }
        }
    }
    @IBAction func indexChanged(_ sender: Any) {
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            self.pickerView.isHidden = true
            self.tableView.isHidden = false
        case 1:
            self.pickerView.isHidden = false
            self.tableView.isHidden = true
        default:
            break
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "WTtoWAY"){
            let viewControllerWAY = segue.destination as? ViewControllerWAY
            let selectedPlace = getSelectedPlace()
            let result = appDelegate.WhichMapANDWhichPos(DestName: selectedPlace)
            dump(result)
            viewControllerWAY?.destination = result
        }
    }
}
