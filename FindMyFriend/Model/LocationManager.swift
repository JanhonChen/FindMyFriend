//
//  LogManager.swift
//  HelloMyPushMessage
//
//  Created by Janhon on 2018/10/31.
//  Copyright © 2018 Cp102. All rights reserved.
//

import Foundation
import SQLite  // SQLite3 是IOS內建的,是C API.

// 10/31 以MessageItem, 作為交換的型別. 是MVC模組化的概念, 將MessageItem與LogManager 綁在一起.

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

struct Locations{
    
    let lat : String
    let lon : String
}

class LocationManager {
    
    static let tableName = "locationLog"
    static let midKey = "mid"
    static let latKey = "latitude"
    static let lonKey = "longitude"

    // SQLite.swift support
    var db: Connection!     // DateBase
    // 資料表
    var logTable = Table(tableName)
    
    // 資料表對應到的欄位
    // Swift 預設的 Int ,若Run 在32位元的CPU裡, 就是Int32. 這樣資料格式會不符,故指定為Int64
    var midColumn = Expression<Int64>(midKey)   // dateBase 裡面的編號.
    var latColumn = Expression<String>(latKey)
    var lonColumn = Expression<String>(lonKey)
    var locationIDs = [Int64]()
    
    init(){
        // Prepare DB filename/path.
        let filemanager = FileManager.default
        let documentsURL = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullURLPath = documentsURL.appendingPathComponent("log.sqlite").path
        var isNewDB = false
        
        if !filemanager.fileExists(atPath: fullURLPath){  //
            isNewDB = true
        }
        
        // Prepare connection of DB.
        do{
            db = try Connection(fullURLPath)  // 執行這一行, 檔案就被建出來了. 故!filemanager.fileExists 要在前面,檢查才有效果.
        } catch {
            assertionFailure("Fail to create connection.")
            return
        }
        
        // Create Table at the first time.
        if isNewDB {
            do{
                let command = logTable.create { (builder) in
                    builder.column(midColumn, primaryKey: true)
                    builder.column(latColumn)
                    builder.column(lonColumn)
                }  // SQL 指令.
                try db.run(command)
                print("Log table is created OK.")
            }catch {
                assertionFailure("Fail to create table: \(error)")
            }
        } else {
            // Keep mid into locationIDs.
            
            do{
                // SELECT * FROM "messageLog";
                for location in try db.prepare(logTable){  // db.prepare 會幫忙準備出array的物件.
                    locationIDs.append(location[midColumn])
                }
                
            } catch {
                assertionFailure("Fail to execute prepare command: \(error)")
            }
            print("There are total \(locationIDs.count) locations in DB.")
        }
    }
    
    var count: Int {
        return locationIDs.count
    }
    
    
    func coodinateAppend(lat: Double, lon: Double){  // 新增
        
        let command = logTable.insert(latColumn <- String(lat), lonColumn <- String(lon))
        
        do{
            let newLocationCoodinate =  try db.run(command)
            locationIDs.append(newLocationCoodinate)
            print("Success to inser a new Coodinate \(newLocationCoodinate), \(lat),\(lon)")
        } catch {
            assertionFailure("Fail to insert a new Coodinate: \(error)")
        }
        
    }
    
    func getLocation(at: Int) -> Locations? {
        guard at >= 0 , at < count else {
            assertionFailure("Invalid friend index.")
            return nil
        }
        let targerLocationID = locationIDs[at]

        // SELECT * FROM "logMessage" WHERE mid == XXXX;
        let results = logTable.filter(midColumn == targerLocationID)
        // Pick the first one.
        do{
            guard let location = try db.pluck(results) else {  // pluck 多筆裡面只挑出一筆.
                assertionFailure("Fail to get the only one result.")
                return nil
            }
            
            return Locations(lat: location[latColumn], lon: location[lonColumn])
            
        } catch {
            print("Pluck fail: \(error)")
        }
        return nil
    }
}
