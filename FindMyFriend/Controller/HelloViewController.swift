//
//  HelloViewController.swift
//  FindMyFriend
//
//  Created by Janhon on 2018/11/5.
//  Copyright © 2018 ImProve. All rights reserved.
//

import UIKit

class HelloViewController: UIViewController  {

    // MARK:- Fixed screen orientation  若要鎖定橫向，將Portrait改成Landscape即可
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
//        return .landscapeLeft
//        return .portrait
    }
    override var shouldAutorotate: Bool {
        return true
    }
    
    @IBOutlet var userNameTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

    @IBAction func userNameTextAction(_ sender: UITextField) {
        guard let name = userNameTextField.text else {
            return
        }
        MY_NAME = name
        print("\(MY_NAME)")
        // Dismiss keyboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 10 ){
            self.userNameTextField.resignFirstResponder()
        }
        }
    @IBAction func myAppLinkButton(_ sender: UIButton) {
    }
}


