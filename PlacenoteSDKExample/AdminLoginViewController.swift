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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let logoutBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(GoBackUser))
        self.navigationItem.rightBarButtonItem  = logoutBarButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        //self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        //print(self.username.text!)

        if (self.username?.text != nil && self.password?.text != nil) {
            let authDetails = AWSCognitoIdentityPasswordAuthenticationDetails(username: self.username!.text!, password: self.password!.text! )
            self.passwordAuthenticationCompletion?.set(result: authDetails)
        }
    }
    
    
    @objc func GoBackUser(){
        print("Here!")
    }
    
    
}


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
                self.dismiss(animated: true, completion: {
                    self.username?.text = nil
                    self.password?.text = nil
                })
            }
        }
    }
}
