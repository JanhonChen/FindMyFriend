//
//  FriendsDownload.swift
//  FindMyFriend
//
//  Created by Janhon on 2018/11/1.
//  Copyright © 2018 ImProve. All rights reserved.
//

import Foundation

struct Friends : Codable {
    let id : String
    let friendName : String
    let lat : String
    let lon : String
    let lastUpdateDateTime : String
    
    enum CodingKeys : String, CodingKey {
        case id = "id"  //變數命名時,大小寫要與 json完全相同.
        case friendName = "friendName"
        case lat = "lat"
        case lon = "lon"
        case lastUpdateDateTime = "lastUpdateDateTime"
    }
}


