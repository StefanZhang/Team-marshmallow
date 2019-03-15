//
//  AdminLoginViewController.swift
//  PlacenoteSDKExample
//
//  Created by Team Herman Miller on 2/25/19.
//  Copyright © 2019 Vertical. All rights reserved.
//
import Foundation
import UIKit
import AWSCognitoIdentityProvider


class AdminLoginViewController: UIViewController {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    var user:AWSCognitoIdentityUser?
    var userAttributes:[AWSCognitoIdentityProviderAttributeType]?
    
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.resetAttributeValues()
        self.fetchUserAttributes()
    }
    
    // AWS cognito checking user attributes, starts login procedure
    func fetchUserAttributes() {
        //self.resetAttributeValues()
        user = AppDelegate.defaultUserPool().currentUser()
        user?.getDetails().continueOnSuccessWith(block: { (task) -> Any? in
            guard task.result != nil else {
                return nil
            }
            self.userAttributes = task.result?.userAttributes
            self.userAttributes?.forEach({ (attribute) in
                print("Name: " + attribute.name!)
            })
            DispatchQueue.main.async {
                //self.setAttributeValues()
            }
            return nil
        })
    }
    
    //  func resetAttributeValues() {
    //    self.lastNameLabel.text = ""
    //    self.firstNameLabel.text = ""
    //    self.usernameLabel.text = ""
    //  }
    //
    //  func setAttributeValues() {
    //    self.lastNameLabel.text = valueForAttribute(name: "family_name")
    //    self.firstNameLabel.text = valueForAttribute(name: "given_name")
    //    self.usernameLabel.text = self.user?.username
    //  }
    // End of login functions for Admin View
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        print(self.username.text!)
        
        /// Need to remove
        self.performSegue(withIdentifier: "showAdmin", sender: self)

        if (self.username?.text != nil && self.password?.text != nil) {
            let authDetails = AWSCognitoIdentityPasswordAuthenticationDetails(username: self.username!.text!, password: self.password!.text! )
            self.passwordAuthenticationCompletion?.set(result: authDetails)
        }
    }
    
}


/// NOT GETTING CALLED
extension AdminLoginViewController: AWSCognitoIdentityPasswordAuthentication {
    
    public func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        self.passwordAuthenticationCompletion = passwordAuthenticationCompletionSource
        DispatchQueue.main.async {
            if (self.username.text == nil) {
                self.username.text = authenticationInput.lastKnownUsername
            }
        }
    }
    
    public func didCompleteStepWithError(_ error: Error?) {
        DispatchQueue.main.async {
            if let error = error as NSError? {
                let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                alertController.addAction(retryAction)
                
                self.present(alertController, animated: true, completion:  nil)
            } else {
                self.username.text = nil
                //self.dismiss(animated: true, completion: nil)
                self.performSegue(withIdentifier: "showAdmin", sender: self)
            }
        }
    }
}
