//
//  ViewControllerFP.swift
//  PlacenoteSDKExample
//
//  Created by xiaofeng Zhang on 3/26/19.
//  Copyright © 2019 Vertical. All rights reserved.
//

import UIKit

class ViewControllerFP: UIViewController {

    @IBOutlet weak var webview: UIWebView!
    var path = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        path = (self.nibBundle?.path(forResource: "FP", ofType: "pdf"))!
        
        let url = NSURL.init(fileURLWithPath: path)
        
        self.webview.loadRequest(URLRequest(url: url as URL))
        
        self.webview.scalesPageToFit = true;
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
