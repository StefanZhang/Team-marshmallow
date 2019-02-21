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
    
    var appdelegate:AppDelegate!
    var tempArray = ["Stumpf", "Weber", "Behar", "Chadwick", "Eames", "Bennett", "Brisel", "Blueprint (ELT)", "Rudder", "Kelley (ELT)", "Action Office (ELT)", "Setu", "Studio 7.5"]
    var search = [String]()
    var searching = false
    var selectedPlace = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tempArray.sort() // sorts list of places
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        self.btnHere.isHidden = true
        //navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        self.hideKeyboard()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searching == false{
            selectedPlace = self.tempArray[indexPath.row]
            print(selectedPlace)
            self.hideKeyboard()
        }
        else{
            selectedPlace = self.search[indexPath.row]
            print(selectedPlace)
            self.searchBarCancelButtonClicked(searchBar)
            // to highlight the selected row after selecting it from a search
            let indexPath2 = IndexPath(row: tempArray.firstIndex(of: selectedPlace)!, section: 0)
            self.tableView.selectRow(at: indexPath2, animated: true, scrollPosition: UITableViewScrollPosition.middle)
            // still a shadow after the row is selected
            // only after using search to find place
            self.hideKeyboard()
        }
        self.btnHere.isHidden = false
    }
    

}

extension UIViewController
{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))
        
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
}

