//
//  webViewController.swift
//  FindMyFriend
//
//  Created by Janhon on 2018/11/5.
//  Copyright © 2018 ImProve. All rights reserved.
//

import UIKit
import WebKit

class webViewController: UIViewController {

    @IBOutlet var mainWebView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let urlString = "https://itunes.apple.com/tw/app/%E7%9A%AE%E8%80%B6%E8%AB%BE/id1440153875?l=en&mt=8"
        guard let url = URL(string: urlString) else {
            assertionFailure("Invaild URL string")
            return
        }
        
        let request = URLRequest(url: url)
        mainWebView.load(request)
        
        // Do any additional setup after loading the view.
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
