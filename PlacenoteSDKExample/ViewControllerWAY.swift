//
//  ViewControllerWAY.swift
//  PlacenoteSDKExample
//
//  Created by John Riley on 2/21/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import UIKit

class ViewControllerWAY: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnHere: UIButton!
    @IBOutlet weak var backbutton: UIButton!
    @IBOutlet weak var btnBack: UIButton!
 
    // Store the destination selected by WT
    var destination : [String] = []

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var tempArray = ["Fetching Places..."] // placeholder when fetching array
    var search = [String]()
    var searching = false // if the user is searching
    var selectedPlace = "" // place that the user picked to go
    var pickerData: [String] = [String]() // to populate the pickerview
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pickerView.isHidden = true // hide the pickerview until the tableview is loaded
        self.btnBack.isHidden = true
        self.btnHere.isHidden = true
        self.segmentedControl.isHidden = true
        SetUpNaviBar() // shows navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        pickerData = ["All Places","Bathroom","Conference Room","Other"] // types of places, hardcoded (for now)
        tempArray.sort() // sorts list of places
        // setup delegates and data sources
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        //navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundBlur2")!)
        searchBar.isUserInteractionEnabled = false
        tableView.isUserInteractionEnabled = false

    }
    
    func SetUpNaviBar(){
        let logoutBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(GoBackUser))
        navigationItem.leftBarButtonItem  = logoutBarButtonItem
        
        
        let logoImage = UIImage(named: "hmCircleLogo")?.withRenderingMode(.alwaysOriginal)
        let logoButton = UIBarButtonItem(image: logoImage, style: .plain, target: self, action: #selector(Nothing))
        logoButton.imageInsets = UIEdgeInsets(top: 0, left: 495, bottom: 00, right: 00)
        navigationItem.rightBarButtonItem = logoButton
        
    }
    
    @objc func GoBackUser(){
        self.backbutton.sendActions(for: .touchUpInside)
    }
    
    @objc func Nothing(){
        
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
        searching = false
        searchBar.text = ""
        self.searchBar.endEditing(true)
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.btnHere.isHidden = false
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
                self.setPlaceArray(Array(Set(self.appDelegate.getDestinationName())))
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
        if (segue.identifier == "WAYtoUM"){
            let viewControllerUM = segue.destination as? ViewControllerUM
            let selectedPlace = getSelectedPlace()
            let result = appDelegate.WhichMapANDWhichPos(DestName: selectedPlace)
            dump(result)
            dump(self.destination)
            
            viewControllerUM?.destination = self.destination
            viewControllerUM?.initialLocation = result
        }
        if(segue.identifier == "WAYtoLocalize"){
            let userLocalizeView = segue.destination as? UserLocalizationViewController
            dump(self.destination)
            
            userLocalizeView?.destination = self.destination
        }
    }
}
