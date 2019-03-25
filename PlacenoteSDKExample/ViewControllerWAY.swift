//
//  ViewControllerWAY.swift
//  PlacenoteSDKExample
//
//  Created by John Riley on 2/21/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import UIKit

class ViewControllerWAY: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var btnHere: UIButton!
    
    // Store the destination selected by WT
    var destination : [String] = []
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var tempArray = ["Fetching Destinations..."]
    var search = [String]()
    var searching = false
    var selectedPlace = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SetUpNaviBar()
        
        tempArray.sort() // sorts list of places
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        //navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
        
        // test destination
        print("This is destination")
        dump(destination)
        
    }
    
    func SetUpNaviBar(){
        
        let MenuButton = UIButton(type: .system)
        let buttonImage = UIImage(named: "menu_icon")
        MenuButton.setImage(buttonImage, for: .normal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: MenuButton)
        
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
    
    func setPlaceArray(){
        tempArray = appDelegate.getDestinationName()
        let farray = tempArray.filter {$0 != "DefaultDest"}
        tempArray = farray
        tempArray.sort()
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            self.setPlaceArray()
        })
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
    }
}

