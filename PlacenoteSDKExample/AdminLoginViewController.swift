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
    @IBOutlet weak var loginButton: UIButton!
    
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loginButton?.isEnabled = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    

    @IBAction func loginPressed(_ sender: AnyObject) {
        print(self.username.text!)
        if (self.username.text != nil && self.password.text != nil) {
            let authDetails = AWSCognitoIdentityPasswordAuthenticationDetails(username: self.username.text!, password: self.password.text! )
            self.passwordAuthenticationCompletion?.set(result: authDetails)
        } else {
            let alertController = UIAlertController(title: "Missing information",
                                                    message: "Please enter a valid user name and password",
                                                    preferredStyle: .alert)
            let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
            alertController.addAction(retryAction)
        }
        
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
                self.username.text = nil
                //self.dismiss(animated: true, completion: nil)
                self.performSegue(withIdentifier: "Admin Mode", sender: AnyObject.self)
            }
        }
    }
}
