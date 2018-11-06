//
//  MasterViewController.swift
//  FindMyFriend
//
//  Created by Janhon on 2018/10/30.
//  Copyright © 2018 ImProve. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    let communicator = Communicator.shared
    var friends = [Friends]()
    let refreshLock = NSLock()
    var shouldRefreshAgain = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        doRefreshJob()
//        navigationItem.leftBarButtonItem = editButtonItem
//        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
//        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
    }
    
    @IBAction func refreshBtnPressed(_ sender: Any) {

        let urlString = "http://class.softarts.cc/FindMyFriends/queryFriendLocations.php?GroupName=cp102"  //資料來源.
        guard URL(string: urlString) != nil else {
            assertionFailure("Invaild URL string")
            return
        }
        doRefreshJob()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    @objc
    func insertNewObject(_ sender: Any) {
//        friends.insert(NSDate(), at: 0)
//        let indexPath = IndexPath(row: 0, section: 0)
//        tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = friends[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let item = friends[indexPath.row]
        let name = item.friendName
        let time = item.lastUpdateDateTime
        cell.textLabel!.text = "\(name)"
        cell.detailTextLabel!.text = "Last seen: \(time) seconds ago."
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            friends.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    

    
    func doRefreshJob(){
        
        // 當retriveMessages 重複呼叫時.
        communicator.queryFriendLocations { (result, error) in
            
            if let error = error {
            print("Get queryFriendLocations error : \(error)")
            return
            }
            print("Send queryFriendLocations OK: \(result!)")
            
            // Decode as [friends]. // 10/26新增
            guard let jsonData = try? JSONSerialization.data(withJSONObject: result as Any, options: .prettyPrinted) else{
                print("Fail to generate jsonData.")
                return
            }
            let decoder = JSONDecoder()
            guard let resultObject = try? decoder.decode(RetriveResult.self, from: jsonData) else{
                print("Fail to decode jsonData.")
                return
            }
            print("resultObject: \(resultObject)")
            guard let friends = resultObject.friends, !friends.isEmpty else{
                print("friends is nil or empty.")
                return
            }
            self.friends = friends
            self.tableView.reloadData()
        }
    }

}
    
    
// MARK : - Structs for incoming messges.
struct RetriveResult : Codable {
    var result : Bool
    var friends : [Friends]?
    
    enum CodingKeys : String, CodingKey {
        case result = "result"
        case friends = "friends"
        }
}
