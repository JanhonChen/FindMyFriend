//
//  Communicator.swift
//  FindMyFriend
//
//  Created by Janhon on 2018/10/24.
//  Copyright © 2018 Cp102. All rights reserved.
//

////標準的singleton 寫法. 適用於多個地方要用.
//class Communicator{
//    static let shared = Communicator()
//    private init(){}
//}

//#if true // false --> test server, true --> official server.
//static let BASEURL = "http://class.softarts.cc/PushMessage/"
//#else
//static let BASEURL = "http://test.softarts.cc/PushMessage/"
//#endif

import Foundation
import Alamofire

let GROUPNAME = "cp102"
var MY_NAME = ""

// JSON Keys
let ID_KEY = "id"  // 朋友的唯一識別。
let USERNAME_KEY = "UserName"
let MESSAGES_KEY = "Messages"
let MESSAGE_KEY = "Message"
let DEVICETOKEN_KEY = "DeviceToken"
let GROUPNAME_KEY = "GroupName"
let LASTMESSAGE_ID_KEY  = "LastMessageID"
let TYPE_KEY = "Type"
let DATA_KEY = "data"
let RESULT_KEY = "result"


let LAT_KEY = "lat"  // 朋友最後回報的緯度。
let LON_KEY = "lon"  // 朋友最後回報的經度。

let FRIENDNAME_KEY = "friendName"  // 朋友的名稱。
let LASTUPDATEDATETIME_KEY = "lastUpdateDateTime"  // 朋友最後更更新位置的時間。


//[String:Any]? dictionary 的型別. 因為json 拿回來的是dictionary
typealias DoneHandler = (_ result: [String:Any]?, _ error: Error?) -> Void


// 10/26 新增
typealias DownloadDoneHandler = (_ result: Data? , _ error: Error?) -> Void

//標準的singleton 寫法.
class Communicator{
    
    // Constants
//    #if FOR_TEST
//    static let BASEURL = "http://test.softarts.cc/FindMyFriends/"   // FOR_TEST = 1時,執行test server.
//    #else
    static let BASEURL = "http://class.softarts.cc/FindMyFriends/"
//    #endif
    let UPDATEDEVICETOKEN_URL = BASEURL + "updateDeviceToken.php"
    let RETRIVE_MESSAGES_URL = BASEURL + "retriveMessages2.php"
    let SEND_MESSAGE_URL = BASEURL + "sendMessage.php"
    let SEND_PHOTOMESSAGE_URL = BASEURL + "sendPhotoMessage.php"
    let PHOTO_BASE_URL = BASEURL + "photos/"
    
    let UPDATEUSERLOCATION = BASEURL + "updateUserLocation.php?"
    let QUERYFRIENDLOCATIONS = BASEURL + "queryFriendLocations.php?"

    static let shared = Communicator()
    private init(){
    }
    
    // MARK: - Public methods
    func update(deviceToken : String, completion: @escaping DoneHandler) {
        
        //包成 dictionary , 比較容易轉成JSON.  內容是根據php要給的值.
        let parameters = [USERNAME_KEY: MY_NAME, DEVICETOKEN_KEY: deviceToken , GROUPNAME_KEY : GROUPNAME ]
     
        doPost(urlString: UPDATEDEVICETOKEN_URL, parameters: parameters, completion: completion)
    }
    

    // MARK: - 回報位置API -- new (homework)
    func updateUserLocation(latitude : Double, longitude : Double , completion: @escaping DoneHandler) {
        
        let urlString = "\(UPDATEUSERLOCATION)GroupName=\(GROUPNAME)&UserName=\(MY_NAME)&Lat=\(latitude)&Lon=\(longitude)"
        let str = urlString
        //return URL to Serch character of using
        let convert = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        doPost(urlString: convert!, completion: completion)
    }
    
    // MARK: - 取得朋友位置API -- new (homework)
    func queryFriendLocations ( completion: @escaping DoneHandler)  {
        
        let urlString = "\(QUERYFRIENDLOCATIONS)GroupName=\(GROUPNAME)"
        let str = urlString
        //return URL to Serch character of using
        let convert = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        doPost(urlString: convert!, completion: completion)
    }
    
    
    //10/25 做SEND_MESSAGE_URL方法.
    func send(text message : String, completion: @escaping DoneHandler) {
        
        let parameters = [USERNAME_KEY: MY_NAME, MESSAGE_KEY: message , GROUPNAME_KEY : GROUPNAME ]
        
        doPost(urlString: SEND_MESSAGE_URL, parameters: parameters, completion: completion)
    }
    
    //10/26 新增. 給檔名, 下載下來後用completion 傳回DoneHandler
    func downloadPhoto(filename : String , completion: @escaping DownloadDoneHandler){
        let finalURLString = PHOTO_BASE_URL + filename
        Alamofire.request(finalURLString).responseData { (response) in
            switch response.result{
            case .success(let data):
                print("Photo Download OK: %id bytes", data.count)
                completion(data,nil)
            case .failure(let error) :
                print("Photo Download Fail: \(error)")
                completion(nil,error)
            }
        }
    }
    
    //10/25 做RETRIVE_MESSAGES_URL方法.
    func retriveMessages(last messageID : Int, completion: @escaping DoneHandler) {
        
        let parameters : [String : Any] = [LASTMESSAGE_ID_KEY: messageID , GROUPNAME_KEY : GROUPNAME ]
        
        doPost(urlString: RETRIVE_MESSAGES_URL, parameters: parameters, completion: completion)
    }
    
    func send(photoMessage data: Data, completion: @escaping DoneHandler){
        let parameters = [USERNAME_KEY: MY_NAME, GROUPNAME_KEY : GROUPNAME ]
        doPost(urlString: SEND_PHOTOMESSAGE_URL, parameters: parameters, data: data, completion: completion)
        print("\(SEND_PHOTOMESSAGE_URL),\(parameters),\(data),\(completion)")
    }
    
    private func doPost(urlString: String, parameters: [String: Any], data : Data ,completion: @escaping DoneHandler) {
     let jsonData = try! JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        Alamofire.upload(multipartFormData: { (formData) in
            formData.append(jsonData, withName: DATA_KEY)
            // fileName: "image.jpg" 因為server 會去rename, 因此這邊可以寫死.
            formData.append(data, withName: "fileToUpload", fileName: "image.jpg", mimeType: "image/jpg")
        }, to: urlString, method: .post) { (encodingResult) in
            switch encodingResult{
//            case .success(let request, let fromDisk, let url): // 只留下request,因為另外兩個參數用不到.
            case .success(let request, _, _):
                print("Post Encoding OK.")
                request.responseJSON { (response) in
                    self.handleJSON(response: response, completion: completion)
                }
            case .failure(let error):
                print("Post Encoding fail: \(error)")
                completion(nil, error)
            }
        }
        
    }
    
    private func doPost(urlString: String, parameters: [String: Any], completion: @escaping DoneHandler) {
        let jsonData = try! JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) //用try! 因為對
        let jsonString = String(data: jsonData, encoding: .utf8)! // 將json 轉成 .utf8
        let finalParamters : [String: Any] = [DATA_KEY: jsonString]
        
        // URLEncoding.default 會將key,value 轉成key = value , 上傳的東西是 data=.....
        // JSONEncoding.default 上傳的東西是 {"data"="....."}
        // let header = ["AuthorizarionKey":"......"]
        Alamofire.request(urlString, method: .post, parameters: finalParamters, encoding: URLEncoding.default).responseJSON { (response) in
            
            self.handleJSON(response: response, completion: completion)
        }
    }
    
    // 上傳及下載位置.
    private func doPost(urlString: String, completion: @escaping DoneHandler) {
    
        Alamofire.request(urlString, method: .post, encoding: URLEncoding.default).responseJSON { (response) in
            self.handleJSON(response: response, completion: completion)
        }
        
       
    }

    
    private func handleJSON(response: DataResponse<Any>, completion: DoneHandler)
        {
            switch response.result{
//            case .success(let json): print("Get success response: \(json)")   // enum的特殊用法 (let json)
            case .success(let json): print("Get success response")
            // json 解不出來時.
            guard let finalJson = json as? [String: Any] else {
                let error = NSError(domain: "Invalid JSON object", code: -1, userInfo: nil)
                completion(nil,error)
                return
                }
            guard let result = finalJson[RESULT_KEY] as? Bool , result == true else{
                let error = NSError(domain: "Server respond false or not result.", code: -1, userInfo: nil)
                completion(nil,error)
                return
            }
                completion(finalJson, nil)
                
            case .failure(let error): print("Server respond error: \(error)")
                completion(nil,error)
            }
    }
    
}


